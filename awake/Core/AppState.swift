import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    private let defaults = UserDefaults.standard

    // Keys for persistent settings
    private let kPreventDisplaySleep = "preventDisplaySleep"
    private let kShowTimeInMenuBar = "showTimeInMenuBar"
    private let kSoundFeedbackEnabled = "soundFeedbackEnabled"
    private let kNotificationsEnabled = "notificationsEnabled"
    private let kRequireCharger = "requireCharger"
    private let kStopOnLowBattery = "stopOnLowBattery"
    private let kBatteryCutoffPercentage = "batteryCutoffPercentage"
    private let kIsClosedLidEnabled = "isClosedLidEnabled"
    private let kIsThermalProtectionEnabled = "isThermalProtectionEnabled"

    // MARK: - Published State
    @Published public var status: SessionStatus = .idle
    @Published public var selectedMode: SessionMode = .timer
    @Published public var selectedDuration: TimeInterval = 3600
    @Published public var selectedTargetDate: Date = Date()

    @Published public var preventDisplaySleep: Bool {
        didSet {
            defaults.set(preventDisplaySleep, forKey: kPreventDisplaySleep)
            if status.isRunning {
                AssertionManager.shared.activate(preventDisplaySleep: preventDisplaySleep)
            }
        }
    }

    @Published public var showTimeInMenuBar: Bool {
        didSet {
            defaults.set(showTimeInMenuBar, forKey: kShowTimeInMenuBar)
            MenuBarController.shared.updateRemainingTimeMenuBar()
        }
    }

    @Published public var soundFeedbackEnabled: Bool {
        didSet {
            defaults.set(soundFeedbackEnabled, forKey: kSoundFeedbackEnabled)
            SoundEffectManager.shared.isEnabled = soundFeedbackEnabled
        }
    }

    @Published public var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: kNotificationsEnabled)
        }
    }

    @Published public var requireCharger: Bool {
        didSet {
            defaults.set(requireCharger, forKey: kRequireCharger)
            evaluatePowerSafeguards()
        }
    }

    @Published public var stopOnLowBattery: Bool {
        didSet {
            defaults.set(stopOnLowBattery, forKey: kStopOnLowBattery)
            evaluatePowerSafeguards()
        }
    }

    @Published public var batteryCutoffPercentage: Double {
        didSet {
            defaults.set(batteryCutoffPercentage, forKey: kBatteryCutoffPercentage)
            evaluatePowerSafeguards()
        }
    }

    @Published public var isClosedLidEnabled: Bool {
        didSet {
            defaults.set(isClosedLidEnabled, forKey: kIsClosedLidEnabled)
            if isClosedLidEnabled && status.isRunning {
                ClosedLidManager.shared.enableClosedLidSleepOverride()
            } else if !isClosedLidEnabled {
                ClosedLidManager.shared.disableClosedLidSleepOverride()
            }
        }
    }

    @Published public var isThermalProtectionEnabled: Bool {
        didSet {
            defaults.set(isThermalProtectionEnabled, forKey: kIsThermalProtectionEnabled)
        }
    }

    @Published public var isThermalPaused: Bool = false
    @Published public var thermalPauseReason: String? = nil

    @Published public var remainingSeconds: TimeInterval = 0
    @Published public var elapsedSeconds: TimeInterval = 0
    @Published public var safeguardAlertMessage: String? = nil

    public var onStatusChanged: ((SessionStatus) -> Void)?
    private var sessionTimer: Timer?

    private init() {
        self.preventDisplaySleep = defaults.object(forKey: kPreventDisplaySleep) != nil ? defaults.bool(forKey: kPreventDisplaySleep) : true
        self.showTimeInMenuBar = defaults.object(forKey: kShowTimeInMenuBar) != nil ? defaults.bool(forKey: kShowTimeInMenuBar) : true
        self.soundFeedbackEnabled = defaults.object(forKey: kSoundFeedbackEnabled) != nil ? defaults.bool(forKey: kSoundFeedbackEnabled) : true
        self.notificationsEnabled = defaults.object(forKey: kNotificationsEnabled) != nil ? defaults.bool(forKey: kNotificationsEnabled) : true
        self.requireCharger = defaults.object(forKey: kRequireCharger) != nil ? defaults.bool(forKey: kRequireCharger) : false
        self.stopOnLowBattery = defaults.object(forKey: kStopOnLowBattery) != nil ? defaults.bool(forKey: kStopOnLowBattery) : true
        self.batteryCutoffPercentage = defaults.object(forKey: kBatteryCutoffPercentage) != nil ? defaults.double(forKey: kBatteryCutoffPercentage) : 20.0
        self.isClosedLidEnabled = defaults.object(forKey: kIsClosedLidEnabled) != nil ? defaults.bool(forKey: kIsClosedLidEnabled) : false
        self.isThermalProtectionEnabled = defaults.object(forKey: kIsThermalProtectionEnabled) != nil ? defaults.bool(forKey: kIsThermalProtectionEnabled) : true
    }

    // MARK: - Session Controls

    public func startSession() {
        safeguardAlertMessage = nil

        // Verify power safeguards before starting
        PowerMonitor.shared.refreshPowerStatus()
        if PowerMonitor.shared.hasBattery {
            if requireCharger && !PowerMonitor.shared.isACConnected {
                safeguardAlertMessage = "Cannot start session: Power adapter required."
                if soundFeedbackEnabled {
                    NotificationManager.shared.playFeedbackSound(type: .safeguardAlert)
                }
                return
            }
            if !PowerMonitor.shared.isACConnected,
               let battery = PowerMonitor.shared.batteryPercentage,
               battery <= batteryCutoffPercentage {
                safeguardAlertMessage = "Cannot start: Battery at \(Int(battery))% is below the \(Int(batteryCutoffPercentage))% safeguard cutoff."
                if soundFeedbackEnabled {
                    NotificationManager.shared.playFeedbackSound(type: .safeguardAlert)
                }
                return
            }
        }

        let now = Date()
        let endsAt: Date?

        switch selectedMode {
        case .timer:
            endsAt = now.addingTimeInterval(selectedDuration)
            remainingSeconds = selectedDuration
        case .until:
            var target = selectedTargetDate
            if target <= now {
                target = Calendar.current.date(byAdding: .day, value: 1, to: target) ?? target
            }
            endsAt = target
            remainingSeconds = max(0, target.timeIntervalSince(now))
        case .unlimited:
            endsAt = nil
            remainingSeconds = 0
        }

        elapsedSeconds = 0
        status = .running(startedAt: now, endsAt: endsAt)

        // Activate IOKit power assertions
        AssertionManager.shared.activate(preventDisplaySleep: preventDisplaySleep)

        // Activate Closed-Lid sleep override if enabled
        if isClosedLidEnabled {
            ClosedLidManager.shared.enableClosedLidSleepOverride()
        }

        // Sound Feedback
        if soundFeedbackEnabled {
            NotificationManager.shared.playFeedbackSound(type: .sessionStarted)
        }

        // Notification Feedback
        if notificationsEnabled {
            let desc: String
            switch selectedMode {
            case .timer:
                desc = "Awake is keeping your Mac active for \(Int(selectedDuration / 60)) minutes."
            case .until:
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                desc = "Awake will keep your Mac active until \(formatter.string(from: endsAt ?? now))."
            case .unlimited:
                desc = "Awake will keep your Mac active indefinitely until stopped."
            }
            NotificationManager.shared.sendNotification(title: "Awake Active", body: desc, identifier: "session-start")
        }

        startTimer()
        CLINotificationObserver.shared.writeStatusFile()
        onStatusChanged?(status)
    }

    public func stopSession(reason: String? = nil) {
        if PresentationModeManager.shared.isPresentationActive {
            PresentationModeManager.shared.stopPresentationMode()
        }
        let wasRunning = status.isRunning

        sessionTimer?.invalidate()
        sessionTimer = nil

        // Release IOKit power assertions
        AssertionManager.shared.deactivate()

        // Release Closed-Lid sleep override
        ClosedLidManager.shared.disableClosedLidSleepOverride()

        DisplayTriggerManager.shared.resetTriggerFlag()
        NetworkGuardManager.shared.resetTriggerFlag()
        isThermalPaused = false
        thermalPauseReason = nil

        objectWillChange.send()
        status = .idle
        remainingSeconds = 0
        elapsedSeconds = 0
        CLINotificationObserver.shared.writeStatusFile()

        if let reason = reason {
            self.safeguardAlertMessage = reason
            if soundFeedbackEnabled {
                NotificationManager.shared.playFeedbackSound(type: .safeguardAlert)
            }
            if notificationsEnabled {
                NotificationManager.shared.sendNotification(
                    title: "Awake Safeguard Triggered",
                    body: reason,
                    identifier: "safeguard-alert"
                )
            }
        } else if wasRunning {
            if soundFeedbackEnabled {
                NotificationManager.shared.playFeedbackSound(type: .sessionEnded)
            }
            if notificationsEnabled {
                NotificationManager.shared.sendNotification(
                    title: "Awake Session Ended",
                    body: "Your Mac has returned to its normal energy saver schedule.",
                    identifier: "session-end"
                )
            }
        }

        onStatusChanged?(status)
    }

    public func toggleSession() {
        if status.isRunning {
            stopSession()
        } else {
            startSession()
        }
    }

    // MARK: - Thermal Overheat Pause & Cooldown Resume
    public func pauseForThermalAlert(reason: String) {
        guard status.isRunning, !isThermalPaused else { return }
        isThermalPaused = true
        thermalPauseReason = reason
        AssertionManager.shared.deactivate()
        ClosedLidManager.shared.disableClosedLidSleepOverride()

        if soundFeedbackEnabled {
            NotificationManager.shared.playFeedbackSound(type: .safeguardAlert)
        }
        if notificationsEnabled {
            NotificationManager.shared.sendNotification(
                title: "⚠️ Overheat Failsafe: Awake Suspended",
                body: reason,
                identifier: "thermal-alert"
            )
        }
        CLINotificationObserver.shared.writeStatusFile()
        onStatusChanged?(status)
    }

    public func resumeFromThermalAlert() {
        guard status.isRunning, isThermalPaused else { return }
        isThermalPaused = false
        thermalPauseReason = nil
        AssertionManager.shared.activate(preventDisplaySleep: preventDisplaySleep)
        if isClosedLidEnabled {
            ClosedLidManager.shared.enableClosedLidSleepOverride()
        }
        if soundFeedbackEnabled {
            NotificationManager.shared.playFeedbackSound(type: .sessionStarted)
        }
        if notificationsEnabled {
            NotificationManager.shared.sendNotification(
                title: "✅ Temperature Normalized",
                body: "SoC temperature cooled down. Sleep prevention resumed.",
                identifier: "thermal-resume"
            )
        }
        CLINotificationObserver.shared.writeStatusFile()
        onStatusChanged?(status)
    }

    public func pauseSessionForThermal(reason: String) {
        pauseForThermalAlert(reason: reason)
    }

    public func resumeSessionFromThermal() {
        resumeFromThermalAlert()
    }

    // MARK: - Time Increments
    public func addDuration(_ seconds: TimeInterval) {
        guard case let .running(startedAt, endsAt) = status, let currentEnd = endsAt else { return }
        let newEnd = currentEnd.addingTimeInterval(seconds)
        status = .running(startedAt: startedAt, endsAt: newEnd)
        remainingSeconds = max(0, newEnd.timeIntervalSince(Date()))
        selectedDuration += seconds
        MenuBarController.shared.updateRemainingTimeMenuBar()
        CLINotificationObserver.shared.writeStatusFile()
    }

    public func addFifteenMinutes() {
        addDuration(15 * 60)
    }

    public func addThirtyMinutes() {
        addDuration(30 * 60)
    }

    public func addOneHour() {
        addDuration(60 * 60)
    }

    // MARK: - Timer Handling
    private func startTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimerTick()
            }
        }
        RunLoop.current.add(sessionTimer!, forMode: .common)
    }

    private func updateTimerTick() {
        guard case let .running(startedAt, endsAt) = status else {
            sessionTimer?.invalidate()
            sessionTimer = nil
            return
        }

        let now = Date()
        let newElapsed = max(0, now.timeIntervalSince(startedAt))

        if let endsAt = endsAt {
            let remaining = endsAt.timeIntervalSince(now)
            if remaining <= 0 {
                if soundFeedbackEnabled {
                    NotificationManager.shared.playFeedbackSound(type: .sessionCompleted)
                }
                if notificationsEnabled {
                    NotificationManager.shared.sendNotification(
                        title: "Awake Session Completed",
                        body: "Your keep-awake timer has finished. Normal sleep settings have been restored.",
                        identifier: "session-complete"
                    )
                }
                stopSession()
                return
            } else {
                objectWillChange.send()
                self.elapsedSeconds = newElapsed
                self.remainingSeconds = remaining
            }
        } else {
            objectWillChange.send()
            self.elapsedSeconds = newElapsed
        }

        MenuBarController.shared.updateRemainingTimeMenuBar()
    }

    // MARK: - Power Safeguard Evaluation
    private func evaluatePowerSafeguards() {
        PowerMonitor.shared.evaluateSafeguards()
    }

    public func handlePowerSourceChange() {
        evaluatePowerSafeguards()
    }

    public func handleBatteryLevelChange() {
        evaluatePowerSafeguards()
    }

    // MARK: - Formatters
    public var remainingTime: TimeInterval {
        return remainingSeconds
    }

    public var remainingTimeFormatted: String {
        guard case .running(_, let endsAt) = status else { return "00:00:00" }
        if endsAt == nil {
            return "Unlimited"
        }
        return AppearanceManager.shared.formatRemainingTime(
            remaining: remainingSeconds,
            total: selectedDuration
        )
    }

    public var elapsedTimeFormatted: String {
        let total = Int(elapsedSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
