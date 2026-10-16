import Foundation
import Combine
import AppKit

@MainActor
public final class CLIInstallerManager: ObservableObject {
    public static let shared = CLIInstallerManager()

    @Published public private(set) var isInstalled: Bool = false
    @Published public private(set) var installedLocation: String? = nil
    @Published public private(set) var installationError: String? = nil

    private let userBinPath = ("~/.local/bin/awake" as NSString).expandingTildeInPath
    private let systemBinPath = "/usr/local/bin/awake"

    private init() {
        checkStatus()
    }

    public func checkStatus() {
        let fm = FileManager.default

        if fm.fileExists(atPath: userBinPath) {
            isInstalled = true
            installedLocation = userBinPath
            installationError = nil
            return
        }

        if fm.fileExists(atPath: systemBinPath) {
            isInstalled = true
            installedLocation = systemBinPath
            installationError = nil
            return
        }

        isInstalled = false
        installedLocation = nil
    }

    public func getSourceCliURL() -> URL? {
        // 1. Inside Application bundle Resources
        if let resourceURL = Bundle.main.resourceURL {
            let bundleCli = resourceURL.appendingPathComponent("awake")
            if FileManager.default.fileExists(atPath: bundleCli.path) {
                return bundleCli
            }
        }

        // 2. Fallback to /Applications/Awake.app/Contents/Resources/awake
        let appBundlePath = "/Applications/Awake.app/Contents/Resources/awake"
        if FileManager.default.fileExists(atPath: appBundlePath) {
            return URL(fileURLWithPath: appBundlePath)
        }

        // 3. Fallback to developer workspace build
        let devPath = "/Users/pawanbhayde/Developer/opensource/awake/awake-cli/awake"
        if FileManager.default.fileExists(atPath: devPath) {
            return URL(fileURLWithPath: devPath)
        }

        return nil
    }

    @discardableResult
    public func installCLI() -> Bool {
        guard let sourceURL = getSourceCliURL() else {
            installationError = "Could not find bundled 'awake' binary."
            return false
        }

        let fm = FileManager.default
        let userDir = ("~/.local/bin" as NSString).expandingTildeInPath

        do {
            if !fm.fileExists(atPath: userDir) {
                try fm.createDirectory(atPath: userDir, withIntermediateDirectories: true)
            }

            // Remove existing symlink or file if present
            if fm.fileExists(atPath: userBinPath) {
                try fm.removeItem(atPath: userBinPath)
            }

            // Create symbolic link
            try fm.createSymbolicLink(atPath: userBinPath, withDestinationPath: sourceURL.path)
            
            checkStatus()
            installationError = nil
            return true
        } catch {
            installationError = "Failed to install symlink: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    public func uninstallCLI() -> Bool {
        let fm = FileManager.default
        var uninstalled = false

        if fm.fileExists(atPath: userBinPath) {
            try? fm.removeItem(atPath: userBinPath)
            uninstalled = true
        }

        if fm.fileExists(atPath: systemBinPath) {
            try? fm.removeItem(atPath: systemBinPath)
            uninstalled = true
        }

        checkStatus()
        installationError = nil
        return uninstalled
    }
}
