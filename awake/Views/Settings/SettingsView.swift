import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var launchManager: LaunchAtLoginManager
    @ObservedObject var closedLidManager: ClosedLidManager
    @ObservedObject var appTriggerManager: AppTriggerManager
    @ObservedObject var globalHotkeyManager: GlobalHotkeyManager
    @ObservedObject var presentationManager: PresentationModeManager
    @ObservedObject var cliInstaller: CLIInstallerManager
    @ObservedObject var displayManager: DisplayTriggerManager = DisplayTriggerManager.shared
    @ObservedObject var networkManager: NetworkGuardManager = NetworkGuardManager.shared
    @ObservedObject var thermalManager: ThermalProtectionManager = ThermalProtectionManager.shared
    @ObservedObject var urlManager: URLSchemeManager = URLSchemeManager.shared
    @ObservedObject var appearanceManager: AppearanceManager = AppearanceManager.shared
    @ObservedObject var soundManager: SoundEffectManager = SoundEffectManager.shared

    @AppStorage("autoAwakeOnExternalDisplay") var autoAwakeOnExternalDisplay: Bool = false
    @AppStorage("disconnectStopsAwake") var disconnectStopsAwake: Bool = true
    @AppStorage("isNetworkGuardEnabled") var isNetworkGuardEnabled: Bool = false
    @AppStorage("networkSpeedThresholdKB") var networkSpeedThresholdKB: Double = 1024.0
    @AppStorage("networkGracePeriodSeconds") var networkGracePeriodSeconds: Double = 20.0

    @State private var selectedTriggerCategory: Int = 0

    public init() {
        self.appState = AppState.shared
        self.launchManager = LaunchAtLoginManager.shared
        self.closedLidManager = ClosedLidManager.shared
        self.appTriggerManager = AppTriggerManager.shared
        self.globalHotkeyManager = GlobalHotkeyManager.shared
        self.presentationManager = PresentationModeManager.shared
        self.cliInstaller = CLIInstallerManager.shared
        self.displayManager = DisplayTriggerManager.shared
        self.networkManager = NetworkGuardManager.shared
        self.thermalManager = ThermalProtectionManager.shared
        self.urlManager = URLSchemeManager.shared
        self.appearanceManager = AppearanceManager.shared
        self.soundManager = SoundEffectManager.shared
    }

    public init(
        appState: AppState,
        launchManager: LaunchAtLoginManager,
        closedLidManager: ClosedLidManager,
        appTriggerManager: AppTriggerManager
    ) {
        self.appState = appState
        self.launchManager = launchManager
        self.closedLidManager = closedLidManager
        self.appTriggerManager = appTriggerManager
        self.globalHotkeyManager = GlobalHotkeyManager.shared
        self.presentationManager = PresentationModeManager.shared
        self.cliInstaller = CLIInstallerManager.shared
        self.displayManager = DisplayTriggerManager.shared
        self.networkManager = NetworkGuardManager.shared
        self.thermalManager = ThermalProtectionManager.shared
        self.urlManager = URLSchemeManager.shared
        self.appearanceManager = AppearanceManager.shared
        self.soundManager = SoundEffectManager.shared
    }

    public init(
        appState: AppState,
        launchManager: LaunchAtLoginManager,
        closedLidManager: ClosedLidManager,
        appTriggerManager: AppTriggerManager,
        globalHotkeyManager: GlobalHotkeyManager
    ) {
        self.appState = appState
        self.launchManager = launchManager
        self.closedLidManager = closedLidManager
        self.appTriggerManager = appTriggerManager
        self.globalHotkeyManager = globalHotkeyManager
        self.presentationManager = PresentationModeManager.shared
        self.cliInstaller = CLIInstallerManager.shared
        self.displayManager = DisplayTriggerManager.shared
        self.networkManager = NetworkGuardManager.shared
        self.thermalManager = ThermalProtectionManager.shared
        self.urlManager = URLSchemeManager.shared
        self.appearanceManager = AppearanceManager.shared
        self.soundManager = SoundEffectManager.shared
    }

    public init(
        appState: AppState,
        launchManager: LaunchAtLoginManager,
        closedLidManager: ClosedLidManager,
        appTriggerManager: AppTriggerManager,
        globalHotkeyManager: GlobalHotkeyManager,
        presentationManager: PresentationModeManager
    ) {
        self.appState = appState
        self.launchManager = launchManager
        self.closedLidManager = closedLidManager
        self.appTriggerManager = appTriggerManager
        self.globalHotkeyManager = globalHotkeyManager
        self.presentationManager = presentationManager
        self.cliInstaller = CLIInstallerManager.shared
        self.displayManager = DisplayTriggerManager.shared
        self.networkManager = NetworkGuardManager.shared
        self.thermalManager = ThermalProtectionManager.shared
        self.urlManager = URLSchemeManager.shared
        self.appearanceManager = AppearanceManager.shared
        self.soundManager = SoundEffectManager.shared
    }

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            presentationTab
                .tabItem {
                    Label("Presentation", systemImage: "tv")
                }

            triggersTab
                .tabItem {
                    Label("Triggers", systemImage: "bolt.badge.automatic")
                }

            batteryTab
                .tabItem {
                    Label("Battery & Power", systemImage: "bolt.batteryblock")
                }

            closedLidTab
                .tabItem {
                    Label("Closed Lid", systemImage: "laptopcomputer")
                }

            developerTab
                .tabItem {
                    Label("CLI", systemImage: "terminal")
                }

            integrationsTab
                .tabItem {
                    Label("Integrations", systemImage: "sparkles")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 530)
        .padding(20)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchManager.isEnabled },
                    set: { launchManager.setLaunchAtLogin(enabled: $0) }
                ))
                .help("Automatically launch Awake when you log into your Mac.")
            } header: {
                Text("Startup").font(.headline)
            }

            Section {
                Toggle("Enable Global Keyboard Shortcut (⌥ ⌘ A)", isOn: $globalHotkeyManager.isEnabled)
                    .help("Press Option-Command-A anywhere to immediately start or stop keep-awake.")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick-Action Gestures").font(.subheadline.bold())

                    HStack(spacing: 12) {
                        Text("⌥ + Click")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("Instant indefinite keep-awake (skips popover)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Text("Double-Click")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("Instant timer keep-awake (starts last duration)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Text("⌥ ⌘ A")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("Toggle Awake from any application or workspace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            } header: {
                Text("Shortcuts & Quick-Actions").font(.headline)
            }

            Section {
                Toggle("System notifications for session events", isOn: $appState.notificationsEnabled)
            } header: {
                Text("Notifications").font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Appearance Tab (Feature 8)

    private var appearanceTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your menu bar glyph style:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(MenuBarIconStyle.allCases) { style in
                            Button(action: {
                                appearanceManager.iconStyle = style
                            }) {
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        // Idle preview
                                        Image(systemName: style.idleSymbolName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary.opacity(0.75))

                                        // Active preview with green dot
                                        HStack(spacing: 3) {
                                            Image(systemName: style.activeSymbolName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.orange)
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                    .padding(.top, 4)

                                    Text(style.displayName)
                                        .font(.system(size: 11, weight: appearanceManager.iconStyle == style ? .bold : .medium))
                                        .foregroundColor(appearanceManager.iconStyle == style ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(appearanceManager.iconStyle == style ? Color.orange.opacity(0.12) : Color.primary.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(appearanceManager.iconStyle == style ? Color.orange : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Menu Bar Icon Style").font(.headline)
            } footer: {
                Text("Changes the icon in your macOS menu bar dynamically in both idle and active states.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Show countdown time in menu bar", isOn: $appState.showTimeInMenuBar)
                    .help("Displays remaining time next to the icon in the menu bar.")

                if appState.showTimeInMenuBar {
                    Picker("Countdown Format", selection: $appearanceManager.countdownStyle) {
                        ForEach(CountdownStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    HStack {
                        Text("Live Preview:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: appearanceManager.iconStyle.activeSymbolName)
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 3.5, height: 3.5)
                            Text(appearanceManager.formatRemainingTime(remaining: 1500, total: 3600))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 2)
                }
            } header: {
                Text("Status Bar Countdown Display").font(.headline)
            }

            Section {
                Toggle("Enable Sound Effects", isOn: $soundManager.isEnabled)

                if soundManager.isEnabled {
                    Picker("Sound Pack", selection: $soundManager.currentPack) {
                        ForEach(SoundPack.allCases) { pack in
                            Text(pack.displayName).tag(pack)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Audition Sound Pack:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let start = soundManager.currentPack.startSoundName {
                            Button("▶ Start (\(start))") {
                                soundManager.previewSound(start)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        if let stop = soundManager.currentPack.stopSoundName {
                            Button("▶ Stop (\(stop))") {
                                soundManager.previewSound(stop)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.top, 2)
                }
            } header: {
                Text("Aesthetic Sound Packs & Acoustic Feedback").font(.headline)
            } footer: {
                Text("Plays subtle, non-intrusive macOS acoustic feedback whenever sessions start, end, or finish.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Triggers Tab (Apps, Display, Network Guard)

    private var triggersTab: some View {
        VStack(spacing: 10) {
            Picker("Trigger Category", selection: $selectedTriggerCategory) {
                Text("Apps").tag(0)
                Text("Display").tag(1)
                Text("Network").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if selectedTriggerCategory == 0 {
                appTriggersForm
            } else if selectedTriggerCategory == 1 {
                displayTriggersForm
            } else {
                networkGuardForm
            }
        }
    }

    private var appTriggersForm: some View {
        Form {
            Section {
                Toggle("Enable App-Based Triggers", isOn: $appTriggerManager.isEnabled)
                    .help("Automatically activates Keep-Awake when specified apps are running.")

                Toggle("Stop session when triggered apps quit", isOn: $appTriggerManager.stopWhenAppsQuit)
                    .help("If enabled, Awake stops sleep prevention once no tracked apps are running.")
            } header: {
                Text("App Automation").font(.headline)
            } footer: {
                Text("Awake monitors the macOS workspace with zero CPU polling and activates automatically when targeted applications open.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                VStack(spacing: 8) {
                    if appTriggerManager.monitoredApps.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "app.dashed")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No Applications Added")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Add Xcode, Final Cut, Zoom, Terminal, or any long-running tool.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    } else {
                        ForEach(appTriggerManager.monitoredApps) { app in
                            HStack(spacing: 10) {
                                if let icon = appTriggerManager.getAppIcon(for: app.bundleIdentifier) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.localizedName)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(app.bundleIdentifier)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if appTriggerManager.isAppCurrentlyRunning(app.bundleIdentifier) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                        Text("Running")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                                }

                                Button(action: {
                                    appTriggerManager.removeApp(bundleIdentifier: app.bundleIdentifier)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Remove trigger")
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    HStack {
                        Spacer()
                        Button(action: selectApplicationViaOpenPanel) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Application…")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("Monitored Applications").font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private var displayTriggersForm: some View {
        Form {
            Section {
                Toggle("Auto-start Keep-Awake when External Display is connected", isOn: $autoAwakeOnExternalDisplay)
                    .help("Automatically triggers Awake when you plug into a monitor, projector, or TV.")

                Toggle("Stop Keep-Awake when External Display is disconnected", isOn: $disconnectStopsAwake)
                    .help("Restores standard energy-saver sleep as soon as you unplug your external monitor.")
            } header: {
                Text("External Display Rules").font(.headline)
            } footer: {
                Text("Display connection changes are monitored via macOS CoreGraphics display reconfiguration callbacks with zero background polling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: displayManager.hasExternalDisplay ? "display.2" : "display")
                        .font(.system(size: 24))
                        .foregroundColor(displayManager.hasExternalDisplay ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayManager.hasExternalDisplay ? "External Display Active" : "Built-in Display Only")
                            .font(.system(size: 13, weight: .bold))

                        Text(displayManager.hasExternalDisplay ? (displayManager.connectedDisplays.joined(separator: ", ")) : "No external displays currently plugged in")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Circle()
                        .fill(displayManager.hasExternalDisplay ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Current Display Status").font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private var networkGuardForm: some View {
        Form {
            Section {
                Toggle("Enable Active Download Guard", isOn: $isNetworkGuardEnabled)
                    .help("Monitors live system network throughput and prevents sleep while active downloads are occurring.")

                if isNetworkGuardEnabled {
                    Picker("Speed Threshold", selection: $networkSpeedThresholdKB) {
                        Text("256 KB/s (Light browsing)").tag(256.0)
                        Text("512 KB/s").tag(512.0)
                        Text("1 MB/s (Recommended)").tag(1024.0)
                        Text("5 MB/s (High-speed files)").tag(5120.0)
                        Text("10 MB/s (Gigabit / Large media)").tag(10240.0)
                    }

                    Picker("Cooldown Grace Period", selection: $networkGracePeriodSeconds) {
                        Text("10 seconds").tag(10.0)
                        Text("20 seconds (Recommended)").tag(20.0)
                        Text("30 seconds").tag(30.0)
                        Text("60 seconds").tag(60.0)
                    }
                }
            } header: {
                Text("Network Activity Monitor").font(.headline)
            } footer: {
                Text("Download Guard samples BSD socket interface counters (`getifaddrs`) to measure inbound network throughput. While downloading above threshold, your Mac is guaranteed not to sleep mid-transfer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isNetworkGuardEnabled {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(networkManager.isGuardActive ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Current Download Rate: \(networkManager.formattedDownloadSpeed)")
                                .font(.system(size: 13, weight: .bold))

                            Text(networkManager.isGuardActive ? "Preventing sleep due to active download" : "Idle (below speed threshold)")
                                .font(.system(size: 11))
                                .foregroundColor(networkManager.isGuardActive ? .green : .secondary)
                        }

                        Spacer()

                        if networkManager.isGuardActive {
                            Text("GUARD ACTIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Live Network Throughput").font(.headline)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func selectApplicationViaOpenPanel() {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose an application to trigger Awake"
        openPanel.prompt = "Add Trigger"
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")

        if openPanel.runModal() == .OK, let url = openPanel.url {
            appTriggerManager.addApp(url: url)
        }
    }

    // MARK: - Battery & Power Tab

    private var batteryTab: some View {
        Form {
            Section {
                Toggle("Require AC power adapter to activate", isOn: $appState.requireCharger)
                    .help("Awake will decline to activate when running solely on battery power.")

                Toggle("Stop session when battery is low", isOn: $appState.stopOnLowBattery)
                    .help("Automatically stops keep-awake if battery level drops below safety threshold.")

                if appState.stopOnLowBattery {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Battery Safety Cutoff:")
                            Spacer()
                            Text("\(Int(appState.batteryCutoffPercentage))%")
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                        }

                        Slider(
                            value: $appState.batteryCutoffPercentage,
                            in: 5...50,
                            step: 5
                        )
                    }
                }
            } header: {
                Text("Battery Protection").font(.headline)
            } footer: {
                Text("When battery drops below the cutoff, Awake automatically drops its power assertions and allows your Mac to sleep safely.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Closed Lid Tab

    private var closedLidTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "laptopcomputer.and.arrow.down")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clamshell Mode / Sleep Override")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Prevents your MacBook from sleeping when the lid is closed, even with no external display attached.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    if !closedLidManager.isHelperInstalled {
                        Text("Helper Tool Required: Clamshell sleep override requires a privileged helper tool installed to modify IOPM system sleep settings.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    HStack {
                        if !closedLidManager.isHelperInstalled {
                            Button(action: {
                                _ = closedLidManager.installHelper()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield")
                                    Text("Install Helper (Admin Auth)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        } else {
                            Button("Uninstall Helper") {
                                _ = closedLidManager.uninstallHelper()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider()

                    Text("Safety & Thermal Guidelines:")
                        .font(.subheadline.bold())

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                        Text("Watchdog Failsafe: Standard sleep is restored automatically whenever Awake quits, session ends, or battery drops.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 13))
                        Text("Always operate on a flat, hard, well-ventilated surface. Never keep a running MacBook closed inside a backpack or sleeve.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Closed Lid Mode").font(.headline)
            }

            Section {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(thermalStatusColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(thermalStatusColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("SoC Temperature: " + String(format: "%.1f°C", thermalManager.currentTemperatureC))
                                .font(.system(size: 13, weight: .bold))

                            Text(thermalManager.statusMessage)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(thermalStatusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(thermalStatusColor.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text(thermalManager.hasSensorsAvailable ? "Real-time Apple Silicon / Intel IOHID hardware sensor query" : "macOS System Thermal Pressure State")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Test Alert") {
                        thermalManager.testThermalAlert()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)

                Toggle("Automatic Thermal Protection", isOn: $thermalManager.isThermalProtectionEnabled)
                    .help("Automatically pauses sleep prevention if temperatures exceed safe limits.")

                if thermalManager.isThermalProtectionEnabled {
                    Picker("Safety Cutoff Temperature", selection: $thermalManager.thermalLimitCelsius) {
                        Text("75°C (Conservative)").tag(75.0)
                        Text("80°C").tag(80.0)
                        Text("85°C (Recommended)").tag(85.0)
                        Text("90°C (Maximum)").tag(90.0)
                    }

                    Picker("Cooldown Resume Temperature", selection: $thermalManager.thermalResumeCelsius) {
                        Text("65°C").tag(65.0)
                        Text("70°C (Recommended)").tag(70.0)
                        Text("75°C").tag(75.0)
                    }

                    Toggle("Apply protection only in Clamshell Mode", isOn: $thermalManager.clamshellOnlyProtection)
                }
            } header: {
                Text("Thermal Protection & Overheat Failsafe").font(.headline)
            } footer: {
                Text("If the SoC temperature reaches the safety limit while keeping your Mac awake, Awake immediately drops sleep prevention and sounds an alert, allowing fans to cool the system down until it reaches the resume threshold.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var thermalStatusColor: Color {
        if thermalManager.isOverheated {
            return .red
        } else if thermalManager.currentTemperatureC >= 75.0 {
            return .orange
        } else {
            return .green
        }
    }

    // MARK: - Presentation Tab

    private var presentationTab: some View {
        Form {
            Section {
                Toggle("Hide Desktop Icons during presentations", isOn: $presentationManager.hideDesktopIcons)
                    .help("Cleanly hides files and folders on your desktop while Presentation Mode is active.")

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Desktop Cleanliness Test")
                            .font(.system(size: 13, weight: .medium))
                        Text(presentationManager.desktopIconsHidden ? "Desktop icons are currently hidden" : "Desktop icons are currently visible")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        presentationManager.testToggleDesktopIcons()
                    }) {
                        Text(presentationManager.desktopIconsHidden ? "Show Icons" : "Hide Icons")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .padding(.vertical, 2)
            } header: {
                Text("Desktop Display").font(.headline)
            } footer: {
                Text("Awake temporarily hides desktop icons using native Finder controls so your desktop looks immaculate on external displays, Zoom, Meet, and projectors. Icons reappear automatically when presentation mode ends.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Mute Notifications via Focus / Shortcuts", isOn: $presentationManager.muteNotifications)
                    .help("Runs a macOS Shortcut to toggle Focus or Do Not Disturb mode.")

                if presentationManager.muteNotifications {
                    HStack {
                        Text("Shortcut Name:")
                            .font(.system(size: 12))
                        TextField("Toggle DND", text: $presentationManager.focusShortcutName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)

                        Spacer()

                        Button(action: {
                            if let url = URL(string: "shortcuts://") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.forward.app")
                                Text("Open Shortcuts")
                            }
                            .font(.system(size: 11))
                        }
                    }
                }
            } header: {
                Text("Do Not Disturb & Focus").font(.headline)
            } footer: {
                Text("To automatically silence incoming banners during presentations, create a 1-action shortcut named 'Toggle DND' in the macOS Shortcuts app with action 'Set Focus -> Toggle Do Not Disturb'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How Presentation Mode Works")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Start Presentation Mode from the Awake menu bar popover or by right-clicking the menu bar icon. Your screen stays fully illuminated, desktop icons disappear cleanly, and personal alerts are muted.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Developer / CLI Tab

    private var developerTab: some View {
        Form {
            Section {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(cliInstaller.isInstalled ? Color.green.opacity(0.15) : Color.primary.opacity(0.06))
                            .frame(width: 36, height: 36)

                        Image(systemName: "terminal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(cliInstaller.isInstalled ? .green : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(cliInstaller.isInstalled ? "CLI Installed" : "CLI Not Installed")
                            .font(.system(size: 13, weight: .bold))

                        if let path = cliInstaller.installedLocation {
                            Text(path)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Install the 'awake' command line binary to your shell PATH.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if cliInstaller.isInstalled {
                        Button("Uninstall") {
                            cliInstaller.uninstallCLI()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Install to PATH") {
                            cliInstaller.installCLI()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding(.vertical, 4)

                if let error = cliInstaller.installationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text("Command Line Interface (CLI)").font(.headline)
            } footer: {
                Text("Symlinks the 'awake' binary to ~/.local/bin/awake so you can invoke it from Terminal, iTerm2, Kitty, or any shell.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Command Wrapper Mode (Keep Mac awake during builds):")
                        .font(.system(size: 12, weight: .semibold))
                    cliCodeSnippet("awake npm run build")
                    cliCodeSnippet("awake docker compose up")
                    cliCodeSnippet("awake -d cargo build --release")

                    Text("Duration Timers & Display Flags:")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 4)
                    cliCodeSnippet("awake -t 30m")
                    cliCodeSnippet("awake -t 2h -d")

                    Text("Control Awake GUI App & Query Status:")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 4)
                    cliCodeSnippet("awake status")
                    cliCodeSnippet("awake --on")
                    cliCodeSnippet("awake --off")
                }
                .padding(.vertical, 4)
            } header: {
                Text("Usage Examples").font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private func cliCodeSnippet(_ code: String) -> some View {
        HStack {
            Text(code)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy command to clipboard")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(6)
    }

    // MARK: - Integrations Tab (Feature 7)

    private var integrationsTab: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                        Text("Apple Shortcuts & Siri")
                            .font(.system(size: 13, weight: .bold))
                    }

                    Text("Awake provides native App Intents and Siri Voice Shortcuts. You can build automated flows in the macOS Shortcuts app or speak directly to Siri.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        siriPhraseRow(phrase: "“Hey Siri, start Awake”", action: "Starts session with default duration")
                        siriPhraseRow(phrase: "“Hey Siri, keep my Mac awake with Awake”", action: "Prevents system sleep")
                        siriPhraseRow(phrase: "“Hey Siri, stop Awake”", action: "Restores normal sleep")
                        siriPhraseRow(phrase: "“Hey Siri, toggle Awake presentation mode”", action: "Toggles clean presentation")
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Siri & Shortcuts").font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Control Awake from Raycast, Alfred, terminal scripts, or browsers using custom URLs.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    VStack(spacing: 6) {
                        urlSchemeRow(url: "awake://toggle", desc: "Toggle keep-awake on/off")
                        urlSchemeRow(url: "awake://start?duration=30m", desc: "Keep awake for 30 minutes")
                        urlSchemeRow(url: "awake://start?duration=1h&display=true", desc: "Keep awake 1 hour with display on")
                        urlSchemeRow(url: "awake://stop", desc: "Stop session and allow sleep")
                        urlSchemeRow(url: "awake://presentation", desc: "Toggle Presentation Mode")
                        urlSchemeRow(url: "awake://clamshell", desc: "Toggle Clamshell Mode")
                        urlSchemeRow(url: "awake://settings", desc: "Open Awake Settings")
                    }

                    if let result = urlManager.lastActionResult {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 11))
                            Text("Last URL Action: \(result)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("URL Scheme (awake://)").font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger Awake in one keystroke from launcher utilities.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Raycast Quicklink / Script Command")
                                .font(.system(size: 12, weight: .semibold))
                            Text(#"Run `open \"awake://toggle\"` or `awake start 30m` in Raycast"#)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Copy Raycast Script") {
                            copyToClipboard(raycastScriptSnippet)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alfred Workflow Action")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add an 'Open URL' action in Alfred with `awake://start?duration={query}`")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Copy Alfred URL") {
                            copyToClipboard("awake://start?duration={query}")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Raycast & Alfred").font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    private func siriPhraseRow(phrase: String, action: String) -> some View {
        HStack {
            Text(phrase)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Text(action)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private func urlSchemeRow(url: String, desc: String) -> some View {
        HStack {
            Text(url)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)

            Spacer()

            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Button(action: {
                copyToClipboard(url)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .help("Copy URL")

            Button("Run") {
                if let u = URL(string: url) {
                    urlManager.handleURL(u)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
    }

    private var raycastScriptSnippet: String {
        """
        #!/bin/bash
        # @raycast.schemaVersion 1
        # @raycast.title Toggle Awake
        # @raycast.mode silent
        # @raycast.packageName Awake
        open "awake://toggle"
        """
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 12) {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .padding(.top, 8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AwakeTheme.primaryGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 3)

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }

            VStack(spacing: 4) {
                Text("Awake")
                    .font(.title2.bold())
                Text("Version 1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("A high-performance, open-source macOS keep-awake utility. 100% Free, no telemetry, no subscriptions.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://github.com/pawanbhayde/awake")!) {
                    Label("GitHub Repository", systemImage: "link")
                }
                .buttonStyle(.link)

                Link(destination: URL(string: "https://github.com/pawanbhayde/awake/issues")!) {
                    Label("Report an Issue", systemImage: "ladybug")
                }
                .buttonStyle(.link)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
