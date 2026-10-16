import SwiftUI

public struct HeaderView: View {
    @ObservedObject var appState: AppState = AppState.shared
    var onOpenSettings: () -> Void = {}
    @State private var isHoveringSettings = false

    public init(onOpenSettings: @escaping () -> Void = {}) {
        self.appState = AppState.shared
        self.onOpenSettings = onOpenSettings
    }

    public init(appState: AppState, onOpenSettings: @escaping () -> Void = {}) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        HStack(spacing: 12) {
            // App Icon
            ZStack {
                Circle()
                    .fill(appState.status.isRunning ? Color.green.opacity(0.15) : Color.primary.opacity(0.06))
                    .frame(width: 32, height: 32)

                Image(systemName: appState.status.isRunning ? "bolt.fill" : "bolt")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(appState.status.isRunning ? .green : .secondary)
            }

            // Title & Status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Awake")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    if appState.status.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)

                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }

                Text(appState.status.isRunning ? "Preventing Mac from sleeping" : "Ready to keep your Mac awake")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Settings Button with hover micro-interaction using native SettingsLink
            SettingsLink {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isHoveringSettings ? .primary : .secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(isHoveringSettings ? Color.primary.opacity(0.08) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                MenuBarController.shared.closePopover(nil)
            })
            .onHover { isHoveringSettings = $0 }
            .help("Awake Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}
