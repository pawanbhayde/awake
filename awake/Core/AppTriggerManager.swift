import Cocoa
import Combine

public struct MonitoredApp: Identifiable, Codable, Equatable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let localizedName: String

    public init(bundleIdentifier: String, localizedName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
    }
}

@MainActor
public final class AppTriggerManager: ObservableObject {
    public static let shared = AppTriggerManager()

    private let userDefaultsKey = "monitoredApps"
    private let kIsEnabled = "isAppTriggersEnabled"
    private let kStopWhenAppsQuit = "appTriggerStopWhenQuit"

    private var cancellables = Set<AnyCancellable>()
    private var isTriggerSessionActive = false

    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: kIsEnabled)
            evaluateRunningApps()
        }
    }

    @Published public var stopWhenAppsQuit: Bool {
        didSet {
            UserDefaults.standard.set(stopWhenAppsQuit, forKey: kStopWhenAppsQuit)
        }
    }

    @Published public var monitoredApps: [MonitoredApp] = [] {
        didSet {
            saveMonitoredApps()
            evaluateRunningApps()
        }
    }

    @Published public var activeTriggerAppName: String? = nil

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: kIsEnabled) != nil ? UserDefaults.standard.bool(forKey: kIsEnabled) : true
        self.stopWhenAppsQuit = UserDefaults.standard.object(forKey: kStopWhenAppsQuit) != nil ? UserDefaults.standard.bool(forKey: kStopWhenAppsQuit) : true

        loadMonitoredApps()
        setupWorkspaceObservers()
        evaluateRunningApps()
    }

    // MARK: - Workspace Observers

    private func setupWorkspaceObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateRunningApps()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateRunningApps()
            }
            .store(in: &cancellables)
    }

    // MARK: - App Evaluation Logic

    public func evaluateRunningApps() {
        guard isEnabled else {
            if isTriggerSessionActive {
                isTriggerSessionActive = false
                activeTriggerAppName = nil
                if AppState.shared.status.isRunning {
                    AppState.shared.stopSession()
                }
            }
            return
        }

        guard !monitoredApps.isEmpty else {
            if isTriggerSessionActive {
                isTriggerSessionActive = false
                activeTriggerAppName = nil
                if AppState.shared.status.isRunning {
                    AppState.shared.stopSession()
                }
            }
            return
        }

        let runningApps = NSWorkspace.shared.runningApplications
        let runningBundleIDs = Set(runningApps.compactMap { $0.bundleIdentifier })

        if let matchingApp = monitoredApps.first(where: { runningBundleIDs.contains($0.bundleIdentifier) }) {
            activeTriggerAppName = matchingApp.localizedName

            // If Awake isn't currently running, start an indefinite keep-awake session
            if !AppState.shared.status.isRunning {
                isTriggerSessionActive = true
                AppState.shared.selectedMode = .unlimited
                AppState.shared.startSession()
            }
        } else {
            // No monitored apps are running
            activeTriggerAppName = nil
            if isTriggerSessionActive {
                isTriggerSessionActive = false
                if stopWhenAppsQuit && AppState.shared.status.isRunning {
                    AppState.shared.stopSession()
                }
            }
        }
    }

    // MARK: - Management

    public func addApp(bundleIdentifier: String, localizedName: String) {
        guard !monitoredApps.contains(where: { $0.bundleIdentifier == bundleIdentifier }) else { return }
        let app = MonitoredApp(bundleIdentifier: bundleIdentifier, localizedName: localizedName)
        monitoredApps.append(app)
    }

    public func addApp(url: URL) {
        guard let bundle = Bundle(url: url) else { return }
        let bundleId = bundle.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        let name = FileManager.default.displayName(atPath: url.path)
        addApp(bundleIdentifier: bundleId, localizedName: name)
    }

    public func removeApp(bundleIdentifier: String) {
        monitoredApps.removeAll(where: { $0.bundleIdentifier == bundleIdentifier })
    }

    public func isAppCurrentlyRunning(_ bundleIdentifier: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bundleIdentifier })
    }

    public func getAppIcon(for bundleIdentifier: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    // MARK: - Persistence

    private func saveMonitoredApps() {
        if let encoded = try? JSONEncoder().encode(monitoredApps) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadMonitoredApps() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([MonitoredApp].self, from: data) else {
            return
        }
        self.monitoredApps = decoded
    }
}
