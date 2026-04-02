import Foundation

// MARK: - Pattern Learning Engine
final class PatternLearningEngine {
    static let shared = PatternLearningEngine()

    private let safeThreshold = 10
    private let usualThreshold = 3

    private init() {}

    func processCompletedRoute(_ route: RouteRecord) {
        let simplified = RouteAnalyzer.shared.simplify(points: route.points)
        var updatedRoute = route
        updatedRoute.points = simplified

        var clusters = RouteStore.shared.loadClusters()

        if let match = RouteAnalyzer.shared.findMatchingCluster(for: updatedRoute, in: clusters) {
            var updated = match
            updated.routeIDs.append(updatedRoute.id)
            updated.frequency += 1
            updated.lastUsed = .now

            let hour = Calendar.current.component(.hour, from: route.startTime)
            if !updated.timeOfDayPattern.contains(hour) {
                updated.timeOfDayPattern.append(hour)
            }

            updated.classification = classify(frequency: updated.frequency, userMarked: route.userMarkedSafe)
            updatedRoute.classification = updated.classification
            updatedRoute.clusterID = updated.id

            RouteStore.shared.updateCluster(updated)
        } else {
            let hour = Calendar.current.component(.hour, from: route.startTime)
            let newCluster = RouteCluster(
                routeIDs: [updatedRoute.id],
                representativeRouteID: updatedRoute.id,
                classification: .unusual,
                frequency: 1,
                lastUsed: .now,
                timeOfDayPattern: [hour]
            )
            updatedRoute.classification = .unusual
            updatedRoute.clusterID = newCluster.id

            clusters.append(newCluster)
            RouteStore.shared.saveClusters(clusters)
        }

        RouteStore.shared.saveRoute(updatedRoute)
    }

    func classify(frequency: Int, userMarked: Bool) -> RouteClassification {
        if userMarked { return .safe }
        if frequency >= safeThreshold { return .safe }
        if frequency >= usualThreshold { return .usual }
        return .unusual
    }

    func reclassifyCluster(id: UUID, markSafe: Bool) {
        var clusters = RouteStore.shared.loadClusters()
        guard let idx = clusters.firstIndex(where: { $0.id == id }) else { return }

        if markSafe {
            clusters[idx].classification = .safe
        } else {
            clusters[idx].classification = classify(frequency: clusters[idx].frequency, userMarked: false)
        }
        RouteStore.shared.saveClusters(clusters)
    }
}
