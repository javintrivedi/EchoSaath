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
        sendBackendSMS(event: event)
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
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    func sendSMSToContacts(event: ProcessedEvent) {
        let contacts = TrustedContactsStore.shared.contacts
        guard !contacts.isEmpty else { return }

        NotificationCenter.default.post(
            name: .triggerSMSAlert,
            object: nil,
            userInfo: ["contacts": contacts, "event": event]
        )
    }

    private func sendBackendSMS(event: ProcessedEvent) {
        let contacts = TrustedContactsStore.shared.contacts
        guard !contacts.isEmpty else { return }
        NotificationService.shared.sendEmergencySMS(
            event: event,
            location: SensorManager.shared.currentLocation,
            contacts: contacts
        )
    }
}

extension Notification.Name {
    static let triggerSMSAlert = Notification.Name("triggerSMSAlert")
}
