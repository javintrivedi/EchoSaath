import UIKit
import UserNotifications
import Foundation
import Combine

class AlertManager: NSObject, ObservableObject {
    static let shared = AlertManager()

    @Published var lastAlertTime: Date?

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    func triggerAlert(event: ProcessedEvent) {
        lastAlertTime = Date()
        sendLocalNotification(event: event)
        sendSMSToContacts(event: event)
    }

    private func sendLocalNotification(event: ProcessedEvent) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ EchoSaath Alert"
        content.body = event.reason
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil // immediate
        )
        UNUserNotificationCenter.current().add(request)

        // Haptic burst for critical alerts
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    // SMS via MessageUI (posts notification to present SMS sheet from UI layer)
    func sendSMSToContacts(event: ProcessedEvent) {
        let contacts = TrustedContactsStore.shared.contacts
        guard !contacts.isEmpty else { return }

        NotificationCenter.default.post(
            name: .triggerSMSAlert,
            object: nil,
            userInfo: ["contacts": contacts, "event": event]
        )
    }
}

extension Notification.Name {
    static let triggerSMSAlert = Notification.Name("triggerSMSAlert")
}
