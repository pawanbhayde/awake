import SwiftUI

@MainActor
public struct ClosedLidCard: View {
    @ObservedObject var appState: AppState
    @ObservedObject var closedLidManager: ClosedLidManager
    @ObservedObject var thermalManager: ThermalProtectionManager

    public init() {
        self.appState = AppState.shared
        self.closedLidManager = ClosedLidManager.shared
        self.thermalManager = ThermalProtectionManager.shared
    }

    public init(appState: AppState) {
        self.appState = appState
        self.closedLidManager = ClosedLidManager.shared
        self.thermalManager = ThermalProtectionManager.shared
    }

    public init(appState: AppState, closedLidManager: ClosedLidManager) {
        self.appState = appState
        self.closedLidManager = closedLidManager
        self.thermalManager = ThermalProtectionManager.shared
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                // Sleek Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(appState.isClosedLidEnabled && closedLidManager.isHelperInstalled ? Color.orange.opacity(0.15) : Color.primary.opacity(0.06))
                        .frame(width: 32, height: 32)

                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(appState.isClosedLidEnabled && closedLidManager.isHelperInstalled ? .orange : .secondary)
                }

                // Text Description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text("Clamshell Mode")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        if closedLidManager.isHelperInstalled {
                            Text("READY")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text("Keep Mac active with lid shut")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Control
                if closedLidManager.isHelperInstalled {
                    Toggle("", isOn: $appState.isClosedLidEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(.orange)
                } else {
                    Button(action: {
                        _ = closedLidManager.installHelper()
                    }) {
                        Text("Setup")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if !closedLidManager.isHelperInstalled {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Requires a one-time authorization to override lid-close sleep.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            } else if appState.isClosedLidEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    if appState.isThermalPaused {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Thermal Protection Active")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)

                                Text(appState.thermalPauseReason ?? "Sleep prevention paused until SoC cools down.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(6)
                    } else {
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(thermalColor(for: thermalManager.currentTemperatureC))

                                Text(String(format: "%.0f°C", thermalManager.currentTemperatureC))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(thermalColor(for: thermalManager.currentTemperatureC))

                                Text("• \(thermalManager.statusMessage)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Capsule())

                            Spacer()

                            Text("Keep on a flat surface")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .awakeCardStyle(isHighlighted: appState.isClosedLidEnabled && closedLidManager.isHelperInstalled)
    }

    private func thermalColor(for temp: Double) -> Color {
        if temp >= thermalManager.thermalLimitCelsius {
            return .red
        } else if temp >= 75.0 {
            return .orange
        } else {
            return .green
        }
    }
}
