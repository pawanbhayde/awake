import Foundation
import Combine
import AppKit

@MainActor
public final class CLINotificationObserver: ObservableObject {
    public static let shared = CLINotificationObserver()

    private let statusPath = "/tmp/awake-status.json"

    private init() {
        setupDistributedListeners()
        writeStatusFile()
    }

    private func setupDistributedListeners() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            forName: NSNotification.Name("com.awake.mac.cli.start"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                AppState.shared.selectedMode = .unlimited
                AppState.shared.startSession()
                CLINotificationObserver.shared.writeStatusFile()
            }
        }

        center.addObserver(
            forName: NSNotification.Name("com.awake.mac.cli.stop"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                AppState.shared.stopSession()
                CLINotificationObserver.shared.writeStatusFile()
            }
        }

        center.addObserver(
            forName: NSNotification.Name("com.awake.mac.cli.presentation"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                PresentationModeManager.shared.togglePresentationMode()
                CLINotificationObserver.shared.writeStatusFile()
            }
        }
    }

    public func writeStatusFile() {
        let state = AppState.shared
        let pres = PresentationModeManager.shared

        let statusDict: [String: Any] = [
            "isRunning": state.status.isRunning,
            "mode": state.selectedMode == .unlimited ? "unlimited" : "timer",
            "remainingSeconds": state.remainingSeconds,
            "preventDisplaySleep": state.preventDisplaySleep,
            "isPresentationActive": pres.isPresentationActive,
            "activeTrigger": AppTriggerManager.shared.activeTriggerAppName as Any,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let data = try? JSONSerialization.data(withJSONObject: statusDict, options: [.prettyPrinted]) {
            try? data.write(to: URL(fileURLWithPath: statusPath), options: .atomic)
        }
    }

    public func clearStatusFile() {
        try? FileManager.default.removeItem(atPath: statusPath)
    }
}
