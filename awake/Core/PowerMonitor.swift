import Foundation
import Combine
import IOKit.ps

@MainActor
public final class PowerMonitor: ObservableObject {
    public static let shared = PowerMonitor()

    @Published public var isACConnected: Bool = true
    @Published public var isCharging: Bool = false
    @Published public var batteryPercentage: Double? = nil
    @Published public var hasBattery: Bool = false

    private var runLoopSource: CFRunLoopSource?

    private init() {
        refreshPowerStatus()
    }

    public func startMonitoring() {
        refreshPowerStatus()

        guard runLoopSource == nil else { return }

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        if let source = IOPSNotificationCreateRunLoopSource({ info in
            guard let info = info else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in
                monitor.handlePowerChange()
            }
        }, context)?.takeRetainedValue() {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    public func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    public func refreshPowerStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            // Likely a desktop Mac (Mac Studio, Mac mini, iMac, Mac Pro)
            self.hasBattery = false
            self.isACConnected = true
            self.isCharging = false
            self.batteryPercentage = nil
            return
        }

        var foundBattery = false

        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if let powerSourceState = desc[kIOPSPowerSourceStateKey as String] as? String {
                self.isACConnected = (powerSourceState == (kIOPSACPowerValue as String))
            }

            if let isChargingNum = desc[kIOPSIsChargingKey as String] as? Bool {
                self.isCharging = isChargingNum
            } else if let isChargingInt = desc[kIOPSIsChargingKey as String] as? Int {
                self.isCharging = (isChargingInt != 0)
            }

            if let current = desc[kIOPSCurrentCapacityKey as String] as? Double,
               let max = desc[kIOPSMaxCapacityKey as String] as? Double, max > 0 {
                self.batteryPercentage = (current / max) * 100.0
                foundBattery = true
            }
        }

        self.hasBattery = foundBattery
    }

    private func handlePowerChange() {
        refreshPowerStatus()
        evaluateSafeguards()
    }

    /// Evaluates battery and power rules against active session
    public func evaluateSafeguards() {
        let appState = AppState.shared
        guard appState.status.isRunning else { return }
        guard hasBattery else { return } // Desktops always remain safe

        // Safeguard 1: Charger required but unplugged
        if appState.requireCharger && !isACConnected {
            appState.stopSession(reason: "Power adapter was unplugged (Require Power Adapter safeguard).")
            return
        }

        // Safeguard 2: Battery level below threshold
        if !isACConnected, let battery = batteryPercentage {
            if battery <= appState.batteryCutoffPercentage {
                let cutoffInt = Int(appState.batteryCutoffPercentage)
                appState.stopSession(reason: "Battery dropped to \(Int(battery))% (below \(cutoffInt)% safeguard limit).")
                return
            }
        }
    }
}
