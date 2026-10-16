import Foundation
import Combine
import AppKit

@MainActor
public final class ClosedLidManager: ObservableObject {
    public static let shared = ClosedLidManager()

    private let sudoersPath = "/etc/sudoers.d/awake_pmset"

    @Published public var isHelperInstalled: Bool = false
    @Published public var isSleepCurrentlyDisabled: Bool = false
    @Published public var installationError: String? = nil

    private init() {
        checkHelperStatus()
    }

    public func checkHelperStatus() {
        isHelperInstalled = FileManager.default.fileExists(atPath: sudoersPath)
    }

    /// Installs the sudoers rule allowing passwordless pmset disablesleep commands
    public func installHelper() -> Bool {
        let command = """
        echo 'ALL ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' > \(sudoersPath) && chmod 0440 \(sudoersPath)
        """

        let script = "do shell script \"\(command)\" with administrator privileges"

        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                self.installationError = error[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
                checkHelperStatus()
                return false
            } else {
                self.installationError = nil
                checkHelperStatus()
                return true
            }
        }
        return false
    }

    /// Removes the sudoers configuration file
    public func uninstallHelper() -> Bool {
        let command = "rm -f \(sudoersPath)"
        let script = "do shell script \"\(command)\" with administrator privileges"

        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                self.installationError = error[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
                checkHelperStatus()
                return false
            } else {
                self.installationError = nil
                checkHelperStatus()
                return true
            }
        }
        return false
    }

    /// Invokes pmset -a disablesleep 1 to keep laptop awake with lid closed
    public func enableClosedLidSleepOverride() {
        guard isHelperInstalled else { return }

        executeCommand("/usr/bin/sudo", arguments: ["/usr/bin/pmset", "-a", "disablesleep", "1"])
        isSleepCurrentlyDisabled = true
    }

    /// Restores default macOS sleep behavior (pmset -a disablesleep 0)
    public func disableClosedLidSleepOverride() {
        guard isHelperInstalled else { return }

        executeCommand("/usr/bin/sudo", arguments: ["/usr/bin/pmset", "-a", "disablesleep", "0"])
        isSleepCurrentlyDisabled = false
    }

    /// Failsafe cleanup to make sure system sleep is never permanently disabled
    public func restoreSystemSleepDefaults() {
        if isHelperInstalled {
            executeCommand("/usr/bin/sudo", arguments: ["/usr/bin/pmset", "-a", "disablesleep", "0"])
        }
        isSleepCurrentlyDisabled = false
    }

    @discardableResult
    private func executeCommand(_ launchPath: String, arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            print("Failed to run command \(launchPath): \(error)")
            return -1
        }
    }
}
