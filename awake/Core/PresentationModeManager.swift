import Foundation
import Combine
import AppKit
import SwiftUI

@MainActor
public final class PresentationModeManager: ObservableObject {
    public static let shared = PresentationModeManager()

    // MARK: - Published State
    @Published public private(set) var isPresentationActive: Bool = false
    @Published public private(set) var desktopIconsHidden: Bool = false

    // MARK: - User Preferences
    @AppStorage("presentationHideDesktopIcons") public var hideDesktopIcons: Bool = true
    @AppStorage("presentationMuteNotifications") public var muteNotifications: Bool = false
    @AppStorage("presentationFocusShortcutName") public var focusShortcutName: String = "Toggle DND"
    @AppStorage("presentationDimDisplays") public var preventDisplaySleepOnly: Bool = true

    // Tracks if desktop icons were hidden prior to presentation
    private var desktopWasOriginallyHidden: Bool = false

    private init() {}

    // MARK: - Presentation Mode Controls

    public func startPresentationMode() {
        guard !isPresentationActive else { return }

        isPresentationActive = true

        // 1. Record existing desktop icon status
        checkOriginalDesktopStatus()

        // 2. Hide Desktop Icons if enabled
        if hideDesktopIcons && !desktopWasOriginallyHidden {
            setDesktopIconsHidden(true)
        }

        // 3. Trigger Do Not Disturb Focus Mode via Shortcuts CLI if configured
        if muteNotifications && !focusShortcutName.isEmpty {
            runShortcutsCli(shortcutName: focusShortcutName)
        }

        // 4. Activate Awake Session with display sleep prevented
        AppState.shared.selectedMode = .unlimited
        AppState.shared.preventDisplaySleep = true
        AppState.shared.startSession()

        // 5. Sound feedback
        if AppState.shared.soundFeedbackEnabled {
            NotificationManager.shared.playFeedbackSound(type: .sessionStarted)
        }
    }

    public func stopPresentationMode() {
        guard isPresentationActive else { return }

        isPresentationActive = false

        // 1. Restore desktop icons if we hid them
        if hideDesktopIcons && !desktopWasOriginallyHidden {
            setDesktopIconsHidden(false)
        }

        // 2. Untrigger / Toggle Do Not Disturb Focus Mode back
        if muteNotifications && !focusShortcutName.isEmpty {
            runShortcutsCli(shortcutName: focusShortcutName)
        }

        // 3. Stop Awake Session
        if AppState.shared.status.isRunning {
            AppState.shared.stopSession()
        }
    }

    public func togglePresentationMode() {
        if isPresentationActive {
            stopPresentationMode()
        } else {
            startPresentationMode()
        }
    }

    // MARK: - Desktop Icon Manipulation

    public func testToggleDesktopIcons() {
        let shouldHide = !desktopIconsHidden
        setDesktopIconsHidden(shouldHide)
    }

    private func checkOriginalDesktopStatus() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "com.apple.finder", "CreateDesktop"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                desktopWasOriginallyHidden = (output == "0" || output.lowercased() == "false")
            } else {
                desktopWasOriginallyHidden = false
            }
        } catch {
            desktopWasOriginallyHidden = false
        }
    }

    private func setDesktopIconsHidden(_ hidden: Bool) {
        desktopIconsHidden = hidden

        Task.detached(priority: .userInitiated) {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            let cmd = hidden
                ? "defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
                : "defaults delete com.apple.finder CreateDesktop 2>/dev/null || defaults write com.apple.finder CreateDesktop -bool true; killall Finder"
            task.arguments = ["-c", cmd]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
        }
    }

    // MARK: - Focus / DND Shortcuts Integration

    private func runShortcutsCli(shortcutName: String) {
        let trimmed = shortcutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task.detached(priority: .userInitiated) {
            // Verify shortcut exists in macOS Shortcuts app before running
            let listTask = Process()
            listTask.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            listTask.arguments = ["list"]
            let listPipe = Pipe()
            listTask.standardOutput = listPipe
            listTask.standardError = Pipe()

            do {
                try listTask.run()
                let data = listPipe.fileHandleForReading.readDataToEndOfFile()
                listTask.waitUntilExit()
                if let output = String(data: data, encoding: .utf8) {
                    let shortcuts = output.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard shortcuts.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
                        // Shortcut not found in macOS Shortcuts library; ignore gracefully without error
                        return
                    }
                }
            } catch {
                return
            }

            // Run shortcut silently with captured standard streams
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            task.arguments = ["run", trimmed]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
        }
    }
}
