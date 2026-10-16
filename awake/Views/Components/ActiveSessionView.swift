import SwiftUI

@MainActor
public struct ActiveSessionView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var appTriggerManager: AppTriggerManager
    @ObservedObject var presentationManager: PresentationModeManager
    @ObservedObject var displayManager: DisplayTriggerManager = DisplayTriggerManager.shared
    @ObservedObject var networkManager: NetworkGuardManager = NetworkGuardManager.shared
    @ObservedObject var thermalManager: ThermalProtectionManager = ThermalProtectionManager.shared

    public init() {
        self.appState = AppState.shared
        self.appTriggerManager = AppTriggerManager.shared
        self.presentationManager = PresentationModeManager.shared
    }

    public init(appState: AppState) {
        self.appState = appState
        self.appTriggerManager = AppTriggerManager.shared
        self.presentationManager = PresentationModeManager.shared
    }

    public init(appState: AppState, appTriggerManager: AppTriggerManager) {
        self.appState = appState
        self.appTriggerManager = appTriggerManager
        self.presentationManager = PresentationModeManager.shared
    }

    public init(appState: AppState, appTriggerManager: AppTriggerManager, presentationManager: PresentationModeManager) {
        self.appState = appState
        self.appTriggerManager = appTriggerManager
        self.presentationManager = presentationManager
    }

    private var modeBadgeTitle: String {
        if presentationManager.isPresentationActive {
            return "PRESENTATION MODE"
        } else if appState.selectedMode == .unlimited {
            return "INDEFINITE KEEP-AWAKE"
        } else {
            return "TIMER ACTIVE"
        }
    }

    private var badgeColor: Color {
        presentationManager.isPresentationActive ? .purple : .green
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Main Active Session HUD Card
            VStack(spacing: 12) {
                // Active Pulse Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 8, height: 8)

                    Text(modeBadgeTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(badgeColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.12))
                .clipShape(Capsule())

                // Big Countdown / Status Display
                if presentationManager.isPresentationActive {
                    VStack(spacing: 6) {
                        Text("Screen-Share Ready")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Display awake • Desktop clean • Zero interruptions")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        // Feature status pills
                        HStack(spacing: 6) {
                            presentationPill(icon: "display", text: "Awake")
                            if presentationManager.hideDesktopIcons {
                                presentationPill(icon: "sparkles", text: "Icons Hidden")
                            }
                            if presentationManager.muteNotifications {
                                presentationPill(icon: "bell.slash", text: "DND")
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } else if appState.selectedMode == .unlimited {
                    VStack(spacing: 4) {
                        Text("Active Until Canceled")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Your Mac will not sleep or turn off display")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 4) {
                        Text(appState.remainingTimeFormatted)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)

                        Text("Remaining time until sleep restores")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // App Trigger Indicator (Feature 1)
                if let activeTrigger = appTriggerManager.activeTriggerAppName, !presentationManager.isPresentationActive {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("Kept awake by \(activeTrigger)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }

                // External Display Trigger Indicator (Feature 5)
                if displayManager.triggeredByDisplay && !presentationManager.isPresentationActive {
                    HStack(spacing: 6) {
                        Image(systemName: "display.2")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Kept awake by External Monitor")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Active Download Guard Indicator (Feature 5)
                if (networkManager.isGuardActive || networkManager.triggeredByNetwork) && !presentationManager.isPresentationActive {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.teal)
                        Text("Download Guard: \(networkManager.formattedDownloadSpeed)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Thermal Protection Pause Banner (Feature 6)
                if appState.isThermalPaused {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                        Text(appState.thermalPauseReason ?? "Sleep prevention paused: SoC overheating.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
                } else if thermalManager.currentTemperatureC >= 75.0 && !presentationManager.isPresentationActive {
                    HStack(spacing: 6) {
                        Image(systemName: "thermometer.high")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                        Text("SoC Warm: \(String(format: "%.0f°C", thermalManager.currentTemperatureC))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Quick Extension Pill Buttons
                if appState.selectedMode == .timer && !presentationManager.isPresentationActive {
                    HStack(spacing: 8) {
                        extensionButton(title: "+15m") {
                            appState.addFifteenMinutes()
                        }
                        extensionButton(title: "+30m") {
                            appState.addThirtyMinutes()
                        }
                        extensionButton(title: "+1h") {
                            appState.addOneHour()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(badgeColor.opacity(0.2), lineWidth: 1)
            )

            // Prominent Stop Button
            Button(action: {
                if presentationManager.isPresentationActive {
                    presentationManager.stopPresentationMode()
                } else {
                    appState.stopSession()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: presentationManager.isPresentationActive ? "xmark.circle.fill" : "stop.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(presentationManager.isPresentationActive ? "End Presentation Mode" : "Deactivate Awake")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(presentationManager.isPresentationActive ? Color.purple.opacity(0.9) : Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func presentationPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.12))
        .foregroundColor(.purple)
        .clipShape(Capsule())
    }

    private func extensionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}
