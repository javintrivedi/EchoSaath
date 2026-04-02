import Foundation
import Combine

class EventProcessor: ObservableObject {
    static let shared = EventProcessor()

    @Published var currentRisk: RiskLevel = .normal
    @Published var recentEvents: [Event] = [] {
        didSet { persistEvents() }
    }

    private var cancellables = Set<AnyCancellable>()
    private var hasSubscribed = false
    private let eventsStorageKey = "echosaath_events"

    private init() {
        loadEvents()
        setupSensorSubscription()
        setupShakeSubscription()
        // Start route learning system
        RouteTracker.shared.startListening()
    }

    // MARK: - Sensor Subscription
    private func setupSensorSubscription() {
        guard !hasSubscribed else { return }
        hasSubscribed = true

        SensorManager.shared.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sensorEvent in
                self?.handle(sensorEvent)
            }
            .store(in: &cancellables)
    }

    // MARK: - Shake Gesture Subscription (from ShakeDetectingWindow)
    private func setupShakeSubscription() {
        NotificationCenter.default.publisher(for: ShakeDetectingWindow.shakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerShakeAlert()
            }
            .store(in: &cancellables)
    }

    private func triggerShakeAlert() {
        trigger(level: .critical, reason: "🚨 Shake SOS triggered!")
    }

    private func handle(_ sensorEvent: SensorEvent) {
        switch sensorEvent {
        case .suddenMotion(let magnitude):
            if magnitude > 3.5 {
                trigger(level: .critical, reason: "Fall detected (magnitude: \(String(format: "%.1f", magnitude)))")
            } else {
                trigger(level: .elevated, reason: "Sudden motion detected (magnitude: \(String(format: "%.1f", magnitude)))")
            }
        case .locationUpdate(let location):
            // Forward to route learning system
            RouteTracker.shared.processLocation(location)
        case .deviceStationary(let duration):
            if duration > 300 {
                trigger(level: .elevated, reason: "Device inactive for \(Int(duration / 60)) minutes")
            }
        }
    }

    // MARK: - Trigger Event
    func trigger(level: RiskLevel, reason: String) {
        let newEvent = Event(reason: reason, riskLevel: level)
        recentEvents.insert(newEvent, at: 0)

        // Keep max 200 events
        if recentEvents.count > 200 {
            recentEvents = Array(recentEvents.prefix(200))
        }

        // Update current risk
        currentRisk = level

        // If critical, send alert
        if level == .critical {
            AlertManager.shared.triggerAlert(
                event: ProcessedEvent(reason: reason, riskLevel: level)
            )
        }
    }

    // MARK: - Resolve Event
    func resolveEvent(id: UUID) {
        recentEvents.removeAll { $0.id == id }
    }

    // MARK: - Test Event
    func addTestEvent() {
        let testReasons = [
            "Test event - normal activity",
            "Test event - elevated risk",
            "Test event - critical alert"
        ]
        let levels: [RiskLevel] = [.normal, .elevated, .critical]
        let reason = testReasons.randomElement()!
        let level = levels.randomElement()!
        trigger(level: level, reason: reason)
    }

    // MARK: - Manual SOS
    func triggerManualSOS() {
        trigger(level: .critical, reason: "🆘 Manual SOS activated!")
    }

    // MARK: - Persistence
    private func persistEvents() {
        let codableEvents = recentEvents.map { CodableEvent(from: $0) }
        if let data = try? JSONEncoder().encode(codableEvents) {
            UserDefaults.standard.set(data, forKey: eventsStorageKey)
        }
    }

    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: eventsStorageKey),
              let codableEvents = try? JSONDecoder().decode([CodableEvent].self, from: data) else { return }
        recentEvents = codableEvents.map { $0.toEvent() }
    }

    func clearAllEvents() {
        recentEvents = []
        UserDefaults.standard.removeObject(forKey: eventsStorageKey)
    }
}

// MARK: - Codable wrapper for Event persistence
private struct CodableEvent: Codable {
    let id: UUID
    let reason: String
    let timestamp: Date
    let riskLevel: RiskLevel

    init(from event: Event) {
        self.id = event.id
        self.reason = event.reason
        self.timestamp = event.timestamp
        self.riskLevel = event.riskLevel
    }

    func toEvent() -> Event {
        Event(id: id, reason: reason, timestamp: timestamp, riskLevel: riskLevel)
    }
}
