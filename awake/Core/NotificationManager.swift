import Foundation
import UserNotifications
import AppKit
import AudioToolbox

@MainActor
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    public func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    public func playFeedbackSound(type: FeedbackSound) {
        switch type {
        case .sessionStarted:
            SoundEffectManager.shared.playStartSound()
        case .sessionEnded:
            SoundEffectManager.shared.playStopSound()
        case .sessionCompleted:
            SoundEffectManager.shared.playCompletedSound()
        case .safeguardAlert:
            if let sound = NSSound(named: "Basso") {
                sound.play()
            }
        }
    }

    // Deliver notification even when app is active
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

public enum FeedbackSound {
    case sessionStarted
    case sessionEnded
    case sessionCompleted
    case safeguardAlert
}
