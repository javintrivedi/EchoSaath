import UIKit
import Combine

// A custom UIWindow subclass that detects device shake gestures
// and publishes them via NotificationCenter for the alert pipeline.
class ShakeDetectingWindow: UIWindow {
    static let shakeNotification = Notification.Name("EchoSaathShakeDetected")

    private var lastShakeTime: Date = .distantPast
    private let cooldownInterval: TimeInterval = 3.0 // Prevent rapid re-triggers

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        guard motion == .motionShake else { return }

        let shakeEnabled = UserDefaults.standard.object(forKey: "shakeToAlert") as? Bool ?? true
        guard shakeEnabled else { return }

        let now = Date()
        guard now.timeIntervalSince(lastShakeTime) >= cooldownInterval else { return }
        lastShakeTime = now

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Post notification for EventProcessor to handle
        NotificationCenter.default.post(name: Self.shakeNotification, object: nil)
    }
}
