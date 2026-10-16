import Foundation
import AppKit
import SwiftUI
import Combine

@MainActor
public final class URLSchemeManager: ObservableObject {
    public static let shared = URLSchemeManager()

    @Published public var lastHandledURL: String? = nil
    @Published public var lastActionResult: String? = nil

    private init() {
        setupAppleEventHandler()
    }

    private func setupAppleEventHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        Task { @MainActor in
            self.handleURL(url)
        }
    }

    public func handleURL(_ url: URL) {
        guard url.scheme?.lowercased() == "awake" else { return }
        lastHandledURL = url.absoluteString

        let host = (url.host ?? "").lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let action = host.isEmpty ? path : host

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        var queryParams: [String: String] = [:]
        for item in queryItems {
            queryParams[item.name.lowercased()] = item.value?.lowercased()
        }

        switch action {
        case "start":
            handleStartAction(queryParams: queryParams)

        case "stop":
            handleStopAction()

        case "toggle":
            handleToggleAction()

        case "presentation":
            handlePresentationAction(queryParams: queryParams)

        case "clamshell":
            handleClamshellAction(queryParams: queryParams)

        case "settings", "preferences":
            handleSettingsAction()

        default:
            lastActionResult = "Unknown action: \(action)"
        }
    }

    private func handleStartAction(queryParams: [String: String]) {
        let appState = AppState.shared

        // Prevent display sleep if requested
        if let displayParam = queryParams["display"] {
            appState.preventDisplaySleep = (displayParam == "true" || displayParam == "1" || displayParam == "yes")
        }

        // Determine duration or mode
        if let modeParam = queryParams["mode"], modeParam == "unlimited" || modeParam == "indefinite" {
            appState.selectedMode = .unlimited
            appState.startSession()
            lastActionResult = "Started Indefinite Keep-Awake"
            return
        }

        if let durationParam = queryParams["duration"] {
            let seconds = parseDurationString(durationParam)
            if seconds > 0 {
                appState.selectedMode = .timer
                appState.selectedDuration = seconds
                appState.startSession()
                lastActionResult = "Started Keep-Awake for \(formatDuration(seconds))"
                return
            }
        }

        // Default start: use current selection or 1 hour
        if appState.selectedMode == .timer && appState.selectedDuration <= 0 {
            appState.selectedDuration = 3600
        }
        appState.startSession()
        lastActionResult = "Started Keep-Awake session"
    }

    private func handleStopAction() {
        AppState.shared.stopSession()
        lastActionResult = "Stopped Keep-Awake session"
    }

    private func handleToggleAction() {
        let appState = AppState.shared
        if appState.status.isRunning {
            appState.stopSession()
            lastActionResult = "Toggled: Stopped Keep-Awake"
        } else {
            appState.selectedMode = .unlimited
            appState.startSession()
            lastActionResult = "Toggled: Started Indefinite Keep-Awake"
        }
    }

    private func handlePresentationAction(queryParams: [String: String]) {
        let presentation = PresentationModeManager.shared
        if let enableParam = queryParams["enable"] {
            let shouldEnable = (enableParam == "true" || enableParam == "1" || enableParam == "yes")
            if shouldEnable && !presentation.isPresentationActive {
                presentation.startPresentationMode()
                lastActionResult = "Enabled Presentation Mode"
            } else if !shouldEnable && presentation.isPresentationActive {
                presentation.stopPresentationMode()
                lastActionResult = "Disabled Presentation Mode"
            }
        } else {
            presentation.togglePresentationMode()
            lastActionResult = presentation.isPresentationActive ? "Enabled Presentation Mode" : "Disabled Presentation Mode"
        }
    }

    private func handleClamshellAction(queryParams: [String: String]) {
        let appState = AppState.shared
        if let enableParam = queryParams["enable"] {
            let shouldEnable = (enableParam == "true" || enableParam == "1" || enableParam == "yes")
            appState.isClosedLidEnabled = shouldEnable
            lastActionResult = shouldEnable ? "Enabled Clamshell Mode" : "Disabled Clamshell Mode"
        } else {
            appState.isClosedLidEnabled.toggle()
            lastActionResult = appState.isClosedLidEnabled ? "Enabled Clamshell Mode" : "Disabled Clamshell Mode"
        }
    }

    private func handleSettingsAction() {
        MenuBarController.shared.openSettings()
        lastActionResult = "Opened Settings"
    }

    // MARK: - Duration Helpers
    private func parseDurationString(_ raw: String) -> TimeInterval {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.hasSuffix("h") {
            let val = String(trimmed.dropLast())
            if let hours = Double(val) {
                return hours * 3600
            }
        } else if trimmed.hasSuffix("m") {
            let val = String(trimmed.dropLast())
            if let mins = Double(val) {
                return mins * 60
            }
        } else if trimmed.hasSuffix("s") {
            let val = String(trimmed.dropLast())
            if let secs = Double(val) {
                return secs
            }
        } else if let directSeconds = Double(trimmed) {
            return directSeconds
        }

        return 0
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
