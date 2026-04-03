import Foundation
import Combine
import WidgetKit

public struct TrustedContact: Codable, Hashable, Identifiable {
    public let id: UUID
    var name: String
    var phoneNumber: String

    public init(id: UUID = UUID(), name: String, phoneNumber: String) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
    }
}

final class TrustedContactsStore: ObservableObject {
    static let shared = TrustedContactsStore()

    @Published private(set) var contacts: [TrustedContact] = [] {
        didSet { persist() }
    }

    private let storageKey = "trustedContacts"
    private var isInitializing = true

    private init() {
        load()
        isInitializing = false
    }

    // MARK: - Public API
    func add(_ contact: TrustedContact) {
        // Avoid duplicates by phone number
        guard !contacts.contains(where: { $0.phoneNumber == contact.phoneNumber }) else { return }
        contacts.append(contact)
    }

    func remove(_ contact: TrustedContact) {
        contacts.removeAll { $0.id == contact.id }
    }

    func update(_ updated: TrustedContact) {
        guard let index = contacts.firstIndex(where: { $0.id == updated.id }) else { return }
        contacts[index] = updated
    }

    func replaceAll(with newContacts: [TrustedContact]) {
        contacts = newContacts
    }

    // MARK: - Persistence
    private func persist() {
        guard !isInitializing else { return }
        do {
            let data = try JSONEncoder().encode(contacts)
            UserDefaults.standard.set(data, forKey: storageKey)
            WidgetDataProvider.shared.updateWidgetData()
        } catch {
            #if DEBUG
            print("[TrustedContactsStore] Failed to persist contacts: \(error)")
            #endif
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([TrustedContact].self, from: data)
            contacts = decoded
        } catch {
            #if DEBUG
            print("[TrustedContactsStore] Failed to load contacts: \(error)")
            #endif
            contacts = []
        }
    }
}
