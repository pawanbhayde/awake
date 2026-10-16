import Foundation
import Combine
import SwiftUI
import AppKit

public enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case coffee = "coffee"
    case eye = "eye"
    case owl = "owl"
    case flame = "flame"
    case bolt = "bolt"
    case sun = "sun"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .coffee: return "Coffee Cup"
        case .eye: return "Awake Eye"
        case .owl: return "Night Owl"
        case .flame: return "Flame"
        case .bolt: return "Lightning"
        case .sun: return "Sun"
        }
    }

    public var idleSymbolName: String {
        switch self {
        case .coffee: return "cup.and.saucer"
        case .eye: return "eye"
        case .owl: return "bird"
        case .flame: return "flame"
        case .bolt: return "bolt"
        case .sun: return "sun.max"
        }
    }

    public var activeSymbolName: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .eye: return "eye.fill"
        case .owl: return "bird.fill"
        case .flame: return "flame.fill"
        case .bolt: return "bolt.fill"
        case .sun: return "sun.max.fill"
        }
    }
}

public enum CountdownStyle: String, CaseIterable, Identifiable {
    case standard = "standard"
    case compact = "compact"
    case pie = "pie"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard: return "Standard (00:00)"
        case .compact: return "Compact (25m / 1.5h)"
        case .pie: return "Progress Glyph (◔ 25m)"
        }
    }
}

@MainActor
public final class AppearanceManager: ObservableObject {
    public static let shared = AppearanceManager()

    private let defaults = UserDefaults.standard
    private let iconStyleKey = "selectedMenuBarIconStyle"
    private let countdownStyleKey = "selectedCountdownStyle"

    @Published public var iconStyle: MenuBarIconStyle {
        didSet {
            defaults.set(iconStyle.rawValue, forKey: iconStyleKey)
            MenuBarController.shared.invalidateIconCache()
            MenuBarController.shared.updateStatusIcon()
        }
    }

    @Published public var countdownStyle: CountdownStyle {
        didSet {
            defaults.set(countdownStyle.rawValue, forKey: countdownStyleKey)
            MenuBarController.shared.updateRemainingTimeMenuBar()
        }
    }

    private init() {
        if let raw = defaults.string(forKey: iconStyleKey), let style = MenuBarIconStyle(rawValue: raw) {
            self.iconStyle = style
        } else {
            self.iconStyle = .coffee
        }

        if let raw = defaults.string(forKey: countdownStyleKey), let style = CountdownStyle(rawValue: raw) {
            self.countdownStyle = style
        } else {
            self.countdownStyle = .standard
        }
    }

    public func formatRemainingTime(remaining: TimeInterval, total: TimeInterval) -> String {
        let safeRemaining = max(0, remaining)
        let hours = Int(safeRemaining) / 3600
        let minutes = (Int(safeRemaining) % 3600) / 60
        let seconds = Int(safeRemaining) % 60

        switch countdownStyle {
        case .standard:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }

        case .compact:
            if hours > 0 {
                let decimalHours = Double(safeRemaining) / 3600.0
                return String(format: "%.1fh", decimalHours)
            } else if minutes > 0 {
                return "\(minutes)m"
            } else {
                return "\(seconds)s"
            }

        case .pie:
            let glyph = getProgressGlyph(remaining: safeRemaining, total: total)
            if hours > 0 {
                let decimalHours = Double(safeRemaining) / 3600.0
                return String(format: "%@ %.1fh", glyph, decimalHours)
            } else if minutes > 0 {
                return "\(glyph) \(minutes)m"
            } else {
                return "\(glyph) \(seconds)s"
            }
        }
    }

    private func getProgressGlyph(remaining: TimeInterval, total: TimeInterval) -> String {
        guard total > 0 else { return "∞" }
        let fractionRemaining = max(0.0, min(1.0, remaining / total))

        // Progress circles from full to empty
        if fractionRemaining > 0.85 {
            return "●"
        } else if fractionRemaining > 0.60 {
            return "◕"
        } else if fractionRemaining > 0.35 {
            return "◑"
        } else if fractionRemaining > 0.10 {
            return "◔"
        } else {
            return "○"
        }
    }
}
