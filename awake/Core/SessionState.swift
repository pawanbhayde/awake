import Foundation

public enum SessionMode: String, CaseIterable, Identifiable, Codable {
    case timer = "Timer"
    case until = "Until"
    case unlimited = "Unlimited"

    public var id: String { rawValue }
}

public enum SessionStatus: Equatable {
    case idle
    case running(startedAt: Date, endsAt: Date?)
    case paused

    public var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }
}

public struct PresetDuration: Identifiable {
    public let id: String
    public let title: String
    public let duration: TimeInterval

    public static let defaults: [PresetDuration] = [
        PresetDuration(id: "15m", title: "15m", duration: 15 * 60),
        PresetDuration(id: "30m", title: "30m", duration: 30 * 60),
        PresetDuration(id: "1h", title: "1h", duration: 60 * 60),
        PresetDuration(id: "2h", title: "2h", duration: 2 * 60 * 60),
        PresetDuration(id: "4h", title: "4h", duration: 4 * 60 * 60),
        PresetDuration(id: "8h", title: "8h", duration: 8 * 60 * 60)
    ]
}
