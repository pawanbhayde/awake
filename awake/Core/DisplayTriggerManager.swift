import Foundation
import AppKit
import Combine

@MainActor
public final class DisplayTriggerManager: ObservableObject {
    public static let shared = DisplayTriggerManager()

    @Published public private(set) var hasExternalDisplay: Bool = false
    @Published public private(set) var connectedDisplays: [String] = []
    @Published public private(set) var triggeredByDisplay: Bool = false

    private var screenObserver: Any?

    private init() {
        checkConnectedDisplays()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                DisplayTriggerManager.shared.handleScreenParametersChanged()
            }
        }
    }

    public func checkConnectedDisplays() {
        let screens = NSScreen.screens
        var externals: [String] = []

        for screen in screens {
            let desc = screen.deviceDescription
            let screenNum = desc[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let isBuiltin = CGDisplayIsBuiltin(screenNum) != 0

            if !isBuiltin {
                externals.append(screen.localizedName)
            }
        }

        self.connectedDisplays = externals
        self.hasExternalDisplay = !externals.isEmpty
    }

    private func handleScreenParametersChanged() {
        let previouslyHadExternal = self.hasExternalDisplay
        checkConnectedDisplays()

        let autoAwake = UserDefaults.standard.bool(forKey: "autoAwakeOnExternalDisplay")
        let autoDisconnect = UserDefaults.standard.object(forKey: "disconnectStopsAwake") as? Bool ?? true

        // Display connected
        if !previouslyHadExternal && hasExternalDisplay && autoAwake {
            if !AppState.shared.status.isRunning {
                triggeredByDisplay = true
                AppState.shared.selectedMode = .unlimited
                AppState.shared.startSession()

                let displayName = connectedDisplays.first ?? "External Display"
                NotificationManager.shared.sendNotification(
                    title: "Display Connected",
                    body: "Awake activated automatically for \(displayName).",
                    identifier: "display-trigger-start"
                )
            }
        }

        // Display disconnected
        if previouslyHadExternal && !hasExternalDisplay && autoDisconnect && triggeredByDisplay {
            if AppState.shared.status.isRunning {
                triggeredByDisplay = false
                AppState.shared.stopSession(reason: "External display disconnected")
                NotificationManager.shared.sendNotification(
                    title: "Display Disconnected",
                    body: "Awake deactivated as external display was unplugged.",
                    identifier: "display-trigger-stop"
                )
            }
        }
    }

    public func resetTriggerFlag() {
        triggeredByDisplay = false
    }
}
