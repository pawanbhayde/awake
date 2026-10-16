import SwiftUI

public struct AwakeTheme {
    // MARK: - Gradients
    public static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.56, blue: 0.20), Color(red: 0.92, green: 0.38, blue: 0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let activeGreenGradient = LinearGradient(
        colors: [Color(red: 0.22, green: 0.82, blue: 0.48), Color(red: 0.12, green: 0.68, blue: 0.36)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let stopRedGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.32, blue: 0.32), Color(red: 0.82, green: 0.20, blue: 0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let subtlePillBackground = Color.primary.opacity(0.06)
    public static let hoverPillBackground = Color.primary.opacity(0.10)
    public static let cardBackground = Color(nsColor: .controlBackgroundColor).opacity(0.6)
    public static let cardBorder = Color.primary.opacity(0.08)
}

// MARK: - Interactive Button Styles

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct CardModifier: ViewModifier {
    var isHighlighted: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isHighlighted ? Color.orange.opacity(0.4) : Color.primary.opacity(0.07),
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

public extension View {
    func awakeCardStyle(isHighlighted: Bool = false) -> some View {
        modifier(CardModifier(isHighlighted: isHighlighted))
    }
}
