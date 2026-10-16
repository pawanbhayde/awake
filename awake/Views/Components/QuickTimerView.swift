import SwiftUI

@MainActor
public struct QuickTimerView: View {
    @ObservedObject var appState: AppState

    public init() {
        self.appState = AppState.shared
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Custom Segmented Mode Selector
            modePicker

            // Active Mode View
            switch appState.selectedMode {
            case .timer:
                timerModeContent
            case .until:
                untilModeContent
            case .unlimited:
                unlimitedModeContent
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(SessionMode.allCases) { mode in
                let isSelected = appState.selectedMode == mode
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.selectedMode = mode
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: iconForMode(mode))
                            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        Text(titleForMode(mode))
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0), radius: 2, y: 1)
                    )
                    .foregroundColor(isSelected ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func iconForMode(_ mode: SessionMode) -> String {
        switch mode {
        case .timer: return "timer"
        case .until: return "target"
        case .unlimited: return "infinity"
        }
    }

    private func titleForMode(_ mode: SessionMode) -> String {
        switch mode {
        case .timer: return "Timer"
        case .until: return "Until"
        case .unlimited: return "Indefinite"
        }
    }

    // MARK: - Timer Mode

    private var timerModeContent: some View {
        VStack(spacing: 12) {
            // 3x2 Preset Grid (Static layout without LazyVGrid overhead)
            VStack(spacing: 7) {
                HStack(spacing: 7) {
                    ForEach(Array(PresetDuration.defaults.prefix(3))) { preset in
                        presetButton(for: preset)
                    }
                }
                HStack(spacing: 7) {
                    ForEach(Array(PresetDuration.defaults.dropFirst(3))) { preset in
                        presetButton(for: preset)
                    }
                }
            }

            // Custom Duration Slider & Steppers
            VStack(spacing: 6) {
                HStack {
                    Text("Duration")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatDuration(appState.selectedDuration))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    Button(action: {
                        adjustDuration(by: -15 * 60)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 20, height: 20)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.selectedDuration <= 15 * 60)

                    // Continuous slider without tick marks; debounced to only mutate on 15-minute changes
                    Slider(
                        value: Binding(
                            get: { appState.selectedDuration },
                            set: { newValue in
                                let step: TimeInterval = 15 * 60
                                let rounded = min(max(15 * 60, (newValue / step).rounded() * step), 24 * 3600)
                                if rounded != appState.selectedDuration {
                                    appState.selectedDuration = rounded
                                }
                            }
                        ),
                        in: (15 * 60)...(24 * 3600)
                    )
                    .tint(.orange)

                    Button(action: {
                        adjustDuration(by: 15 * 60)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 20, height: 20)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.selectedDuration >= 24 * 3600)
                }
            }
            .padding(.top, 4)
        }
    }

    private func presetButton(for preset: PresetDuration) -> some View {
        let isSelected = abs(appState.selectedDuration - preset.duration) < 1
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.12)) {
                appState.selectedDuration = preset.duration
            }
        }) {
            Text(preset.title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(AwakeTheme.primaryGradient) : AnyShapeStyle(Color.primary.opacity(0.05)))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: isSelected ? Color.orange.opacity(0.2) : Color.clear, radius: 3, y: 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func adjustDuration(by delta: TimeInterval) {
        let newDuration = min(max(15 * 60, appState.selectedDuration + delta), 24 * 3600)
        withAnimation(.easeInOut(duration: 0.12)) {
            appState.selectedDuration = newDuration
        }
    }

    // MARK: - Until Mode

    private var untilModeContent: some View {
        VStack(spacing: 10) {
            // Quick until chips
            HStack(spacing: 6) {
                quickUntilChip(title: "5:00 PM", hour: 17, minute: 0)
                quickUntilChip(title: "8:00 PM", hour: 20, minute: 0)
                quickUntilChip(title: "11:00 PM", hour: 23, minute: 0)
            }

            HStack {
                Text("Exact Target Time:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                DatePicker(
                    "",
                    selection: $appState.selectedTargetDate,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.stepperField)
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private func quickUntilChip(title: String, hour: Int, minute: Int) -> some View {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        var target = calendar.date(from: comps) ?? Date()
        if target <= Date() {
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }

        let isSelected = calendar.isDate(appState.selectedTargetDate, equalTo: target, toGranularity: .minute)

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.12)) {
                appState.selectedTargetDate = target
            }
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(AwakeTheme.primaryGradient) : AnyShapeStyle(Color.primary.opacity(0.06)))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Unlimited Mode

    private var unlimitedModeContent: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "infinity")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.top, 4)

            Text("Indefinite Keep-Awake")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            Text("Your Mac will remain powered and awake continuously until manually stopped.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }
}
