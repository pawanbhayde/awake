import Foundation
import Combine
import SwiftUI
import AppKit

public enum SoundPack: String, CaseIterable, Identifiable {
    case subtleClicks = "subtleClicks"
    case modernChimes = "modernChimes"
    case crystalGlass = "crystalGlass"
    case softBells = "softBells"
    case silent = "silent"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .subtleClicks: return "Subtle Clicks (Tink & Pop)"
        case .modernChimes: return "Modern Chimes (Hero & Funk)"
        case .crystalGlass: return "Crystal Glass (Glass & Bottle)"
        case .softBells: return "Soft Bells (Ping & Pop)"
        case .silent: return "Muted / Silent"
        }
    }

    public var startSoundName: String? {
        switch self {
        case .subtleClicks: return "Tink"
        case .modernChimes: return "Hero"
        case .crystalGlass: return "Glass"
        case .softBells: return "Ping"
        case .silent: return nil
        }
    }

    public var stopSoundName: String? {
        switch self {
        case .subtleClicks: return "Pop"
        case .modernChimes: return "Funk"
        case .crystalGlass: return "Bottle"
        case .softBells: return "Pop"
        case .silent: return nil
        }
    }

    public var completeSoundName: String? {
        switch self {
        case .subtleClicks: return "Tink"
        case .modernChimes: return "Hero"
        case .crystalGlass: return "Glass"
        case .softBells: return "Ping"
        case .silent: return nil
        }
    }
}

@MainActor
public final class SoundEffectManager: ObservableObject {
    public static let shared = SoundEffectManager()

    private let defaults = UserDefaults.standard
    private let soundEnabledKey = "isSoundFeedbackEnabled"
    private let soundPackKey = "selectedSoundPack"

    @Published public var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: soundEnabledKey)
        }
    }

    @Published public var currentPack: SoundPack {
        didSet {
            defaults.set(currentPack.rawValue, forKey: soundPackKey)
        }
    }

    private init() {
        if defaults.object(forKey: soundEnabledKey) != nil {
            self.isEnabled = defaults.bool(forKey: soundEnabledKey)
        } else {
            self.isEnabled = true
        }

        if let raw = defaults.string(forKey: soundPackKey), let pack = SoundPack(rawValue: raw) {
            self.currentPack = pack
        } else {
            self.currentPack = .subtleClicks
        }
    }

    public func playStartSound() {
        guard isEnabled else { return }
        if let soundName = currentPack.startSoundName {
            playSoundNamed(soundName)
        }
    }

    public func playStopSound() {
        guard isEnabled else { return }
        if let soundName = currentPack.stopSoundName {
            playSoundNamed(soundName)
        }
    }

    public func playCompletedSound() {
        guard isEnabled else { return }
        if let soundName = currentPack.completeSoundName {
            playSoundNamed(soundName)
        }
    }

    public func previewSound(_ name: String) {
        playSoundNamed(name)
    }

    private func playSoundNamed(_ name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.stop()
            sound.play()
        }
    }
}
