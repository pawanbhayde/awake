import SwiftUI

@MainActor
public struct PopoverView: View {
    @Environment(\.openSettings) private var openSettingsAction
    @ObservedObject var appState: AppState
    @ObservedObject var powerMonitor: PowerMonitor

    public init() {
        self.appState = AppState.shared
        self.powerMonitor = PowerMonitor.shared
    }

    public init(appState: AppState, powerMonitor: PowerMonitor) {
        self.appState = appState
        self.powerMonitor = powerMonitor
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView {
                MenuBarController.shared.openSettings()
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Safeguard Alert Banner (if triggered)
            if let alert = appState.safeguardAlertMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                        .padding(.top, 1)

                    Text(alert)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 4)

                    Button(action: {
                        withAnimation {
                            appState.safeguardAlertMessage = nil
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Main Content Area
            VStack(spacing: 14) {
                if appState.status.isRunning {
                    ActiveSessionView(appState: appState)
                } else {
                    QuickTimerView(appState: appState)

                    // Display Sleep Option Card
                    displaySleepCard

                    // Closed Lid Card
                    ClosedLidCard(appState: appState)

                    // Presentation Mode Card
                    presentationModeCard

                    // Primary Start Button
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            appState.startSession()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Start Keep-Awake")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AwakeTheme.primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: Color.orange.opacity(0.3), radius: 6, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(16)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            // Sleek Footer with Live Power Status
            footerView
        }
        .frame(width: 330)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            MenuBarController.shared.swiftUIOpenSettings = {
                openSettingsAction()
            }
        }
    }

    // MARK: - Display Sleep Card

    private var displaySleepCard: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(appState.preventDisplaySleep ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                    .frame(width: 32, height: 32)

                Image(systemName: appState.preventDisplaySleep ? "display" : "moon.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(appState.preventDisplaySleep ? .orange : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Keep Display Awake")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(appState.preventDisplaySleep ? "Display will remain illuminated" : "Display sleeps to save energy")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $appState.preventDisplaySleep)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.orange)
        }
        .padding(12)
        .awakeCardStyle(isHighlighted: appState.preventDisplaySleep)
    }

    // MARK: - Presentation Mode Card

    private var presentationModeCard: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "tv")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Presentation Mode")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Clean desktop • Display awake")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    PresentationModeManager.shared.startPresentationMode()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("Present")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.purple.opacity(0.15))
                .foregroundColor(.purple)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .awakeCardStyle(isHighlighted: false)
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack(alignment: .center) {
            if powerMonitor.hasBattery {
                HStack(spacing: 5) {
                    Image(systemName: batteryIconName)
                        .font(.system(size: 12))
                        .foregroundColor(powerMonitor.isCharging ? .green : (powerMonitor.isACConnected ? .orange : .secondary))

                    if let pct = powerMonitor.batteryPercentage {
                        Text("\(Int(pct))%")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    if powerMonitor.isACConnected {
                        Text("• Power Adapter")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "macmini")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Desktop Mac")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
    }

    private var batteryIconName: String {
        if powerMonitor.isCharging {
            return "bolt.batteryblock.fill"
        }
        guard let pct = powerMonitor.batteryPercentage else {
            return "battery.100"
        }
        if pct > 80 {
            return "battery.100"
        } else if pct > 50 {
            return "battery.75"
        } else if pct > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
}
