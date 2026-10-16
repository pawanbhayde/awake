import Foundation
import Combine
import AppKit
import SwiftUI
import IOKit

@MainActor
public final class ThermalProtectionManager: ObservableObject {
    public static let shared = ThermalProtectionManager()

    // MARK: - Published State
    @Published public var currentTemperatureC: Double = 45.0
    @Published public var currentThermalState: ProcessInfo.ThermalState = .nominal
    @Published public var isThermalProtectionActive: Bool = false
    @Published public var hasSensorsAvailable: Bool = false
    @Published public var statusMessage: String = "Normal"

    public var isOverheated: Bool {
        return isThermalProtectionActive || currentThermalState == .critical || currentThermalState == .serious
    }

    // MARK: - Settings (Stored in UserDefaults)
    @AppStorage("isThermalProtectionEnabled") public var isThermalProtectionEnabled: Bool = true
    @AppStorage("thermalLimitCelsius") public var thermalLimitCelsius: Double = 85.0
    @AppStorage("thermalResumeCelsius") public var thermalResumeCelsius: Double = 72.0
    @AppStorage("clamshellOnlyProtection") public var clamshellOnlyProtection: Bool = false

    // MARK: - Private Properties
    private var sampleTimer: Timer?
    private var thermalObserver: NSObjectProtocol?
    private let sensorReader = SensorReader()
    private var wasProtectionTriggered = false

    private init() {
        checkSensors()
        setupThermalObserver()
        startMonitoring()
    }

    deinit {
        sampleTimer?.invalidate()
        if let observer = thermalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func checkSensors() {
        if let initialTemp = sensorReader.readMaxTemperature() {
            currentTemperatureC = initialTemp
            hasSensorsAvailable = true
        } else {
            hasSensorsAvailable = false
        }
        currentThermalState = ProcessInfo.processInfo.thermalState
        updateStatusMessage()
    }

    private func setupThermalObserver() {
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                ThermalProtectionManager.shared.handleThermalStateChanged()
            }
        }
    }

    public func startMonitoring() {
        sampleTimer?.invalidate()
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                ThermalProtectionManager.shared.sampleTemperature()
            }
        }
    }

    public func sampleTemperature() {
        currentThermalState = ProcessInfo.processInfo.thermalState

        if let temp = sensorReader.readMaxTemperature() {
            currentTemperatureC = temp
            hasSensorsAvailable = true
        }

        updateStatusMessage()
        evaluateThermalSafety()
    }

    private func handleThermalStateChanged() {
        currentThermalState = ProcessInfo.processInfo.thermalState
        updateStatusMessage()
        evaluateThermalSafety()
    }

    private func updateStatusMessage() {
        switch currentThermalState {
        case .nominal:
            statusMessage = currentTemperatureC >= thermalLimitCelsius ? "Overheating" : "Normal"
        case .fair:
            statusMessage = "Elevated"
        case .serious:
            statusMessage = "High Thermal Pressure"
        case .critical:
            statusMessage = "Critical Thermal Throttling"
        @unknown default:
            statusMessage = "Normal"
        }
    }

    // MARK: - Failsafe Evaluation

    private func evaluateThermalSafety() {
        guard isThermalProtectionEnabled else {
            if isThermalProtectionActive {
                resumeKeepAwakeAfterCooling()
            }
            return
        }

        let appState = AppState.shared
        guard appState.status.isRunning else {
            if isThermalProtectionActive {
                isThermalProtectionActive = false
                wasProtectionTriggered = false
            }
            return
        }

        // If configured for clamshell-only, verify clamshell mode is active
        if clamshellOnlyProtection && !appState.isClosedLidEnabled {
            if isThermalProtectionActive {
                resumeKeepAwakeAfterCooling()
            }
            return
        }

        let isOverheating = (hasSensorsAvailable && currentTemperatureC >= thermalLimitCelsius) ||
                            (currentThermalState == .critical) ||
                            (appState.isClosedLidEnabled && currentThermalState == .serious)

        if isOverheating && !isThermalProtectionActive {
            triggerThermalProtection()
        } else if isThermalProtectionActive {
            let isCooledDown = (hasSensorsAvailable && currentTemperatureC <= thermalResumeCelsius) ||
                               (!hasSensorsAvailable && (currentThermalState == .nominal || currentThermalState == .fair))

            if isCooledDown {
                resumeKeepAwakeAfterCooling()
            }
        }
    }

    private func triggerThermalProtection() {
        isThermalProtectionActive = true
        wasProtectionTriggered = true

        let tempFormatted = String(format: "%.0f°C", currentTemperatureC)
        let alertReason = "SoC temperature reached \(tempFormatted) (safety limit: \(Int(thermalLimitCelsius))°C). Sleep prevention paused to cool down."

        AppState.shared.pauseSessionForThermal(reason: alertReason)

        // Play alert feedback sound
        NSSound(named: "Basso")?.play()

        // Send high priority notification
        NotificationManager.shared.sendNotification(
            title: "🔥 Thermal Protection Triggered",
            body: "Mac temperature reached \(tempFormatted). Awake paused keep-awake to allow fans and heatsinks to cool the system.",
            identifier: "thermal-alert"
        )
    }

    private func resumeKeepAwakeAfterCooling() {
        isThermalProtectionActive = false
        wasProtectionTriggered = false

        let tempFormatted = String(format: "%.0f°C", currentTemperatureC)
        AppState.shared.resumeSessionFromThermal()

        NotificationManager.shared.playFeedbackSound(type: .sessionStarted)
        NotificationManager.shared.sendNotification(
            title: "❄️ Thermal Cooldown Complete",
            body: "Mac cooled to \(tempFormatted). Sleep prevention has been safely restored.",
            identifier: "thermal-cooldown"
        )
    }

    public func testThermalAlert() {
        let tempFormatted = String(format: "%.0f°C", currentTemperatureC)
        NSSound(named: "Basso")?.play()
        NotificationManager.shared.sendNotification(
            title: "🔥 [Test] Thermal Protection Alert",
            body: "Test simulated high temperature (\(tempFormatted)). Failsafe would drop sleep assertions and notify you.",
            identifier: "thermal-test"
        )
    }

    // MARK: - Sensor Reader via IOHIDEventSystemClient
    private final class SensorReader {
        private typealias IOHIDEventSystemClientCreateType = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
        private typealias IOHIDEventSystemClientSetMatchingType = @convention(c) (AnyObject, CFDictionary) -> Void
        private typealias IOHIDEventSystemClientCopyServicesType = @convention(c) (AnyObject) -> CFArray?
        private typealias IOHIDServiceClientCopyEventWithType = @convention(c) (AnyObject, Int64, Int32, Int64) -> AnyObject?
        private typealias IOHIDEventGetFloatValueType = @convention(c) (AnyObject, Int32) -> Double

        private var clientCreate: IOHIDEventSystemClientCreateType?
        private var clientSetMatching: IOHIDEventSystemClientSetMatchingType?
        private var copyServices: IOHIDEventSystemClientCopyServicesType?
        private var copyEvent: IOHIDServiceClientCopyEventWithType?
        private var getFloat: IOHIDEventGetFloatValueType?

        init() {
            if let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) {
                if let sym = dlsym(handle, "IOHIDEventSystemClientCreate") {
                    clientCreate = unsafeBitCast(sym, to: IOHIDEventSystemClientCreateType.self)
                }
                if let sym = dlsym(handle, "IOHIDEventSystemClientSetMatching") {
                    clientSetMatching = unsafeBitCast(sym, to: IOHIDEventSystemClientSetMatchingType.self)
                }
                if let sym = dlsym(handle, "IOHIDEventSystemClientCopyServices") {
                    copyServices = unsafeBitCast(sym, to: IOHIDEventSystemClientCopyServicesType.self)
                }
                if let sym = dlsym(handle, "IOHIDServiceClientCopyEvent") {
                    copyEvent = unsafeBitCast(sym, to: IOHIDServiceClientCopyEventWithType.self)
                }
                if let sym = dlsym(handle, "IOHIDEventGetFloatValue") {
                    getFloat = unsafeBitCast(sym, to: IOHIDEventGetFloatValueType.self)
                }
            }
        }

        func readMaxTemperature() -> Double? {
            guard let clientCreate = clientCreate,
                  let clientSetMatching = clientSetMatching,
                  let copyServices = copyServices,
                  let copyEvent = copyEvent,
                  let getFloat = getFloat else {
                return nil
            }

            guard let clientObj = clientCreate(kCFAllocatorDefault)?.takeRetainedValue() else {
                return nil
            }

            let matchingDict: [String: Any] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5]
            clientSetMatching(clientObj, matchingDict as CFDictionary)

            guard let services = copyServices(clientObj) as? [AnyObject], !services.isEmpty else {
                return nil
            }

            var maxTemp: Double = 0.0
            for service in services {
                // Event type 15 = kIOHIDEventTypeTemperature
                if let event = copyEvent(service, 15, 0, 0) {
                    let temp = getFloat(event, 15 << 16)
                    if temp > 15.0 && temp < 125.0 {
                        if temp > maxTemp {
                            maxTemp = temp
                        }
                    }
                }
            }

            return maxTemp > 0 ? maxTemp : nil
        }
    }
}
