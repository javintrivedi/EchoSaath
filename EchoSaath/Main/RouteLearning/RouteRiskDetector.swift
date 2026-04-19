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
    private let learningKey = "learningPhaseStartDate"

    @Published var isDeviating = false // Track current deviation state

    // MARK: - Learning Phase

    /// Returns the persisted learning start date, creating and saving it if it doesn't exist yet.
    /// Anchored to midnight of the installation day so each calendar day counts as one full day.
    private var learningStartDate: Date {
        if let stored = UserDefaults.standard.object(forKey: learningKey) as? Date {
            return stored
        }
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: learningKey)
        return today
    }

    private var daysPassed: Int {
        Calendar.current.dateComponents([.day], from: learningStartDate, to: Date()).day ?? 0
    }

    private var isLearningPhase: Bool { daysPassed < 10 }

    var isLearning: Bool { isLearningPhase }

    var learningProgress: String {
        if daysPassed >= 10 {
            return "Personalized Route Enabled"
        } else {
            return "Day \(daysPassed + 1)/10"
        }
    }

    /// Resets the learning phase so progress restarts from Day 1/10.
    func resetLearning() {
        UserDefaults.standard.removeObject(forKey: learningKey)
    }

    var knownRoutesCount: Int {
        RouteStore.shared.loadClusters().count
    }

    private init() {}

    // MARK: - Live Route Checks

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
                EventProcessor.shared.triggerRouteDeviationAlert(
                    reason: "Route deviation detected — \(Int(minDeviation))m from your usual path"
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
