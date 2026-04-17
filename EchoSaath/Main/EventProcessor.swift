import Foundation
import Combine
import CoreLocation
import UIKit

class EventProcessor: ObservableObject {
    static let shared = EventProcessor()

    @Published var currentRisk: RiskLevel = .normal
    @Published var currentRiskScore: Double = 0 // 0 to 100
    @Published var isAlerting = false 
    @Published var isCountingDown = false
    @Published var recentEvents: [ProcessedEvent] = [] {
        didSet { persistEvents() }
    }
    
    private var pendingReason: String = ""
    private let storageKey = "echosaath_events"

    @Published var showSafetyPrompt: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadEvents()
        subscribeToSensors()
        _ = WatchConnectivityManager.shared // Initialize watch link
    }

    private func subscribeToSensors() {
        SensorManager.shared.eventPublisher
            .sink { [weak self] event in
                self?.handleSensorEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleSensorEvent(_ event: SensorEvent) {
        switch event {
        case .suddenMotion(let magnitude):
            evaluateAndTrigger(magnitude: magnitude)
        case .locationUpdate:
            // Could trigger re-evaluation of route risk
            break
        case .deviceStationary(let duration):
            evaluateAndTrigger(duration: duration)
        }
    }

    func evaluateAndTrigger(magnitude: Double? = nil, duration: TimeInterval? = nil) {
        var score: Double = 0
        var alertComponents: [String] = []
        
        // 1. G-Force Impact (0-50+ pts)
        if let mag = magnitude {
            let shakeEnabled = UserDefaults.standard.object(forKey: "shakeToAlert") as? Bool ?? true
            guard shakeEnabled else { return }
            
            if mag > 3.5 { 
                score += 100 // Immediate trigger
                alertComponents.append("Sudden shake/impact")
            } else if mag > 2.5 { 
                score += 60 // Threshold for critical
                alertComponents.append("Significant motion")
            }
        }
        
        // 2. Inactivity/Stasis (0-40 pts)
        if let dur = duration {
            if dur > 30 { 
                score += 40
                alertComponents.append("Extended inactivity")
            } else if dur > 15 { 
                score += 20
                alertComponents.append("Brief inactivity")
            }
        }
        
        // 3. Route Deviation (Contextual Multiplier)
        if RouteRiskDetector.shared.isDeviating {
            score *= 1.5
            alertComponents.append("Off-route deviation")
        }

        // 4. Update Published Score
        self.currentRiskScore = min(100, score)

        let reason = alertComponents.isEmpty ? "Unusual activity detected" : alertComponents.joined(separator: ", ")
        
        if score >= 60 {
            trigger(level: .critical, reason: reason)
        } else if score >= 30 {
            currentRisk = .elevated
        } else {
            currentRisk = .normal
        }
    }

    func trigger(level: RiskLevel, reason: String) {
        guard level == .critical else { 
            let event = ProcessedEvent(
                reason: reason, 
                riskLevel: level, 
                latitude: SensorManager.shared.currentLocation?.coordinate.latitude,
                longitude: SensorManager.shared.currentLocation?.coordinate.longitude
            )
            DispatchQueue.main.async {
                self.recentEvents.insert(event, at: 0)
                self.currentRisk = level
            }
            return 
        }
        
        if isCountingDown { return }
        
        self.pendingReason = reason
        DispatchQueue.main.async {
            self.isCountingDown = true
            self.isAlerting = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func finalizeAlert() {
        let event = ProcessedEvent(
            reason: pendingReason, 
            riskLevel: .critical,
            latitude: SensorManager.shared.currentLocation?.coordinate.latitude,
            longitude: SensorManager.shared.currentLocation?.coordinate.longitude
        )
        
        DispatchQueue.main.async {
            self.recentEvents.insert(event, at: 0)
            self.isCountingDown = false
            self.isAlerting = false
            self.currentRisk = .critical
            
            // Trigger actual alert manager
            AlertManager.shared.triggerAlert(reason: self.pendingReason, location: SensorManager.shared.currentLocation)
        }
    }
    
    func cancelCountdown() {
        DispatchQueue.main.async {
            self.isCountingDown = false
            self.isAlerting = false
            self.currentRisk = .normal
            self.currentRiskScore = 0
        }
    }

    func triggerManualSOS() {
        trigger(level: .critical, reason: "Manual SOS button pressed")
    }

    func requestSafetyConfirmation(reason: String) {
        self.pendingReason = reason
        DispatchQueue.main.async {
            self.showSafetyPrompt = true
        }
    }

    func resolveSafetyPrompt(isSafe: Bool) {
        DispatchQueue.main.async {
            self.showSafetyPrompt = false
            if !isSafe {
                self.trigger(level: .critical, reason: "User reported unsafe situation during route deviation")
            }
        }
    }

    func addTestEvent() {
        trigger(level: .critical, reason: "Manual Test Trigger")
    }

    func clearAllEvents() {
        recentEvents = []
        currentRisk = .normal
        currentRiskScore = 0
    }

    private func persistEvents() {
        if let data = try? JSONEncoder().encode(recentEvents) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ProcessedEvent].self, from: data) {
            self.recentEvents = decoded
        }
    }
}
