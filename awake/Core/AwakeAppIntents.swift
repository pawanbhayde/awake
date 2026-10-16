import Foundation
import AppIntents

// MARK: - 1. Start Awake Intent
public struct StartAwakeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Awake Session"
    public static var description = IntentDescription("Starts keeping your Mac awake for a specified duration or indefinitely.")

    @Parameter(title: "Duration (Minutes)", default: 60)
    public var durationMinutes: Int

    @Parameter(title: "Keep Display Awake", default: false)
    public var keepDisplayAwake: Bool

    @Parameter(title: "Indefinite Keep-Awake", default: false)
    public var isIndefinite: Bool

    public static var parameterSummary: some ParameterSummary {
        Summary("Keep Mac awake for \(\.$durationMinutes) minutes") {
            \.$keepDisplayAwake
            \.$isIndefinite
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        appState.preventDisplaySleep = keepDisplayAwake

        if isIndefinite {
            appState.selectedMode = .unlimited
            appState.startSession()
            return .result(dialog: "Awake is keeping your Mac active indefinitely.")
        } else {
            let durationSeconds = Double(max(1, durationMinutes)) * 60.0
            appState.selectedMode = .timer
            appState.selectedDuration = durationSeconds
            appState.startSession()
            return .result(dialog: "Awake is keeping your Mac active for \(durationMinutes) minutes.")
        }
    }
}

// MARK: - 2. Stop Awake Intent
public struct StopAwakeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Stop Awake Session"
    public static var description = IntentDescription("Stops any active keep-awake session and restores standard energy-saver sleep.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        AppState.shared.stopSession()
        return .result(dialog: "Awake session stopped. Your Mac will sleep according to system energy settings.")
    }
}

// MARK: - 3. Toggle Awake Intent
public struct ToggleAwakeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Awake"
    public static var description = IntentDescription("Toggles keep-awake state on or off.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        if appState.status.isRunning {
            appState.stopSession()
            return .result(dialog: "Awake stopped.")
        } else {
            appState.selectedMode = .unlimited
            appState.startSession()
            return .result(dialog: "Awake activated indefinitely.")
        }
    }
}

// MARK: - 4. Toggle Presentation Intent
public struct TogglePresentationIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Presentation Mode"
    public static var description = IntentDescription("Toggles presentation mode, locking the screen awake, hiding desktop clutter, and suppressing notifications.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        PresentationModeManager.shared.togglePresentationMode()
        let isActive = PresentationModeManager.shared.isPresentationActive
        let message = isActive ? "Presentation mode activated with clean desktop." : "Presentation mode ended."
        return .result(dialog: "\(message)")
    }
}

// MARK: - 5. Toggle Clamshell Intent
public struct ToggleClamshellIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Clamshell Mode"
    public static var description = IntentDescription("Toggles clamshell keep-awake allowing your Mac to stay active with the lid shut.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let appState = AppState.shared
        appState.isClosedLidEnabled.toggle()
        let status = appState.isClosedLidEnabled ? "enabled" : "disabled"
        return .result(dialog: "Clamshell mode \(status).")
    }
}

// MARK: - 6. App Shortcuts Provider (Siri & Shortcuts App)
public struct AwakeShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartAwakeIntent(),
            phrases: [
                "Start \(.applicationName)",
                "Keep my Mac awake with \(.applicationName)",
                "Prevent Mac sleep with \(.applicationName)"
            ],
            shortTitle: "Start Awake",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: StopAwakeIntent(),
            phrases: [
                "Stop \(.applicationName)",
                "Turn off \(.applicationName)",
                "Allow Mac to sleep with \(.applicationName)"
            ],
            shortTitle: "Stop Awake",
            systemImageName: "moon.fill"
        )
        AppShortcut(
            intent: ToggleAwakeIntent(),
            phrases: [
                "Toggle \(.applicationName)",
                "Switch \(.applicationName)"
            ],
            shortTitle: "Toggle Awake",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: TogglePresentationIntent(),
            phrases: [
                "Start \(.applicationName) presentation",
                "Toggle \(.applicationName) presentation mode"
            ],
            shortTitle: "Presentation Mode",
            systemImageName: "tv"
        )
    }
}
