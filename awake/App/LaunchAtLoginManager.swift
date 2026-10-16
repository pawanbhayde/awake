import Foundation
import Combine
import ServiceManagement
import SwiftUI

@MainActor
public final class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    @Published public var isEnabled: Bool = false

    private init() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    public func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        } catch {
            print("Failed to toggle launch at login: \(error.localizedDescription)")
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    public func refreshStatus() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }
}
