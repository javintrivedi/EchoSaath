import Foundation
import Combine

// MARK: - Notification Log Entry
struct NotificationLogEntry: Codable, Identifiable {
    let id: UUID
    let type: NotificationType
    let recipient: String
    let recipientName: String
    let message: String
    let timestamp: Date
    var status: DeliveryStatus
    var retryCount: Int
    var errorMessage: String?

    init(id: UUID = UUID(), type: NotificationType, recipient: String, recipientName: String = "", message: String, timestamp: Date = .now, status: DeliveryStatus = .pending, retryCount: Int = 0, errorMessage: String? = nil) {
        self.id = id; self.type = type; self.recipient = recipient; self.recipientName = recipientName; self.message = message; self.timestamp = timestamp; self.status = status; self.retryCount = retryCount; self.errorMessage = errorMessage
    }

    enum NotificationType: String, Codable { case welcomeEmail = "Welcome Email"; case emergencySMS = "Emergency SMS" }
    enum DeliveryStatus: String, Codable { case pending = "Pending"; case sent = "Sent"; case failed = "Failed" }
}

// MARK: - Notification Logger
final class NotificationLogger: ObservableObject {
    static let shared = NotificationLogger()
    @Published private(set) var logs: [NotificationLogEntry] = []
    private let storageKey = "echosaath_notification_logs"
    private let maxLogs = 200

    private init() { loadLogs() }

    func log(type: NotificationLogEntry.NotificationType, recipient: String, recipientName: String = "", message: String, status: NotificationLogEntry.DeliveryStatus = .pending) -> UUID {
        let entry = NotificationLogEntry(type: type, recipient: recipient, recipientName: recipientName, message: message, status: status)
        logs.insert(entry, at: 0)
        if logs.count > maxLogs { logs = Array(logs.prefix(maxLogs)) }
        persistLogs()
        return entry.id
    }

    func markSent(id: UUID) { updateStatus(id: id, status: .sent, error: nil) }
    func markFailed(id: UUID, error: String) { updateStatus(id: id, status: .failed, error: error) }
    func incrementRetry(id: UUID) {
        guard let idx = logs.firstIndex(where: { $0.id == id }) else { return }
        logs[idx].retryCount += 1; logs[idx].status = .pending; persistLogs()
    }

    var pendingCount: Int { logs.filter { $0.status == .pending }.count }
    var failedCount: Int { logs.filter { $0.status == .failed }.count }
    var recentLogs: [NotificationLogEntry] { Array(logs.prefix(50)) }
    func clearAll() { logs = []; persistLogs() }

    private func updateStatus(id: UUID, status: NotificationLogEntry.DeliveryStatus, error: String?) {
        guard let idx = logs.firstIndex(where: { $0.id == id }) else { return }
        logs[idx].status = status; logs[idx].errorMessage = error; persistLogs()
    }
    private func persistLogs() { if let data = try? JSONEncoder().encode(logs) { UserDefaults.standard.set(data, forKey: storageKey) } }
    private func loadLogs() {
        guard let data = UserDefaults.standard.data(forKey: storageKey), let decoded = try? JSONDecoder().decode([NotificationLogEntry].self, from: data) else { return }
        logs = decoded
    }
}
