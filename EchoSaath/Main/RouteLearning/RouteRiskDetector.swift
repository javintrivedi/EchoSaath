import Foundation
import CoreLocation
import Combine

// MARK: - Route Risk Detector
final class RouteRiskDetector: ObservableObject {
    static let shared = RouteRiskDetector()

    private let deviationThreshold: Double = 300 // meters
    private let unexpectedStopDuration: TimeInterval = 300 // 5 min
    private var lastAlertTime: Date = .distantPast
    private let alertCooldown: TimeInterval = 120 // 2 min between alerts
    
    @Published var isDeviating = false // Track current deviation state

    private var isLearningPhase: Bool {
        let key = "learningPhaseStartDate"
        let defaults = UserDefaults.standard
        let startDate: Date
        if let storedDate = defaults.object(forKey: key) as? Date {
            startDate = storedDate
        } else {
            startDate = Date()
            defaults.set(startDate, forKey: key)
        }
        
        // 10-day learning phase
        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysPassed < 10
    }
    
    var isLearning: Bool { isLearningPhase }
    
    var learningProgress: String {
        let key = "learningPhaseStartDate"
        let defaults = UserDefaults.standard
        let startDate = (defaults.object(forKey: key) as? Date) ?? Date()
        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        if daysPassed >= 10 {
            return "Fully Personalized"
        } else {
            return "Day \(daysPassed + 1)/10"
        }
    }
    
    var knownRoutesCount: Int {
        RouteStore.shared.loadClusters().count
    }

    private init() {}

    func checkLiveRoute(points: [RoutePoint], currentLocation: CLLocation) {
        guard !isLearningPhase else { return } // Skip alerts during the 10-day learning phase
        guard Date().timeIntervalSince(lastAlertTime) > alertCooldown else { return }

        let clusters = RouteStore.shared.loadClusters()
        let safeClusters = clusters.filter { $0.classification == .safe || $0.classification == .usual }

        guard !safeClusters.isEmpty else { return }

        // Check deviation from all known safe/usual routes
        var minDeviation = Double.greatestFiniteMagnitude
        for cluster in safeClusters {
            let distance = RouteAnalyzer.shared.deviationDistance(livePoints: points, from: cluster)
            if distance < minDeviation {
                minDeviation = distance
            }
        }
        
        if minDeviation <= deviationThreshold {
            self.isDeviating = false
        }

        if minDeviation > deviationThreshold {
            self.isDeviating = true
            lastAlertTime = .now
            DispatchQueue.main.async {
                EventProcessor.shared.requestSafetyConfirmation(
                    reason: "⚠️ Route deviation detected — \(Int(minDeviation))m from known safe route"
                )
            }
        }
    }

    func checkUnexpectedStop(location: CLLocation, stoppedDuration: TimeInterval) {
        guard !isLearningPhase else { return }
        guard stoppedDuration > unexpectedStopDuration else { return }
        guard Date().timeIntervalSince(lastAlertTime) > alertCooldown else { return }

        let clusters = RouteStore.shared.loadClusters()
        let allRoutePoints = clusters.compactMap { RouteStore.shared.route(by: $0.representativeRouteID) }
            .flatMap { $0.points }

        let isNearKnownRoute = allRoutePoints.contains { point in
            location.distance(from: point.clLocation) < 200
        }

        if !isNearKnownRoute {
            lastAlertTime = .now
            DispatchQueue.main.async {
                EventProcessor.shared.requestSafetyConfirmation(
                    reason: "⚠️ Unexpected stop in unfamiliar area for \(Int(stoppedDuration / 60)) min"
                )
            }
        }
    }
}
