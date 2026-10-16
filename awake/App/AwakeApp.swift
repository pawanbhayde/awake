import SwiftUI
import AppKit

@main
struct AwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .onOpenURL { url in
                    URLSchemeManager.shared.handleURL(url)
                }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification authorization
        NotificationManager.shared.requestAuthorization()

        // Start battery and power source monitoring
        PowerMonitor.shared.startMonitoring()

        // Verify helper installation status
        ClosedLidManager.shared.checkHelperStatus()

        // Setup menu bar status item and popover
        MenuBarController.shared.setup()

        // Initialize App Triggers observer
        _ = AppTriggerManager.shared

        // Initialize Global Keyboard Hotkeys
        _ = GlobalHotkeyManager.shared

        // Initialize CLI IPC and Installer
        _ = CLINotificationObserver.shared
        _ = CLIInstallerManager.shared

        // Initialize Display & Network Triggers
        _ = DisplayTriggerManager.shared
        _ = NetworkGuardManager.shared

        // Initialize Thermal Protection
        _ = ThermalProtectionManager.shared

        // Initialize URL Scheme handler
        _ = URLSchemeManager.shared
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            URLSchemeManager.shared.handleURL(url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        CLINotificationObserver.shared.clearStatusFile()
        // Safely restore desktop and stop presentation mode if active
        PresentationModeManager.shared.stopPresentationMode()
        // Safely end keep-awake sessions and release any power assertions
        AppState.shared.stopSession()
        PowerMonitor.shared.stopMonitoring()
        ClosedLidManager.shared.restoreSystemSleepDefaults()
        GlobalHotkeyManager.shared.unregisterHotkey()
    }
}
