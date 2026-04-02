import Foundation
import CoreLocation

// MARK: - Route Analyzer
final class RouteAnalyzer {
    static let shared = RouteAnalyzer()

    /// Hausdorff distance threshold for clustering (meters)
    private let clusterThreshold: Double = 150

    /// Ramer-Douglas-Peucker epsilon (meters)
    private let simplifyEpsilon: Double = 20

    private init() {}

    // MARK: - Ramer-Douglas-Peucker Simplification

    func simplify(points: [RoutePoint]) -> [RoutePoint] {
        guard points.count > 2 else { return points }
        return rdpSimplify(points: points, epsilon: simplifyEpsilon)
    }

    private func rdpSimplify(points: [RoutePoint], epsilon: Double) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        var maxDistance: Double = 0
        var maxIndex = 0

        let start = points.first!.clLocation
        let end = points.last!.clLocation

        for i in 1..<(points.count - 1) {
            let d = perpendicularDistance(
                point: points[i].clLocation,
                lineStart: start,
                lineEnd: end
            )
            if d > maxDistance {
                maxDistance = d
                maxIndex = i
            }
        }

        if maxDistance > epsilon {
            let left = rdpSimplify(points: Array(points[0...maxIndex]), epsilon: epsilon)
            let right = rdpSimplify(points: Array(points[maxIndex...]), epsilon: epsilon)
            return Array(left.dropLast()) + right
        } else {
            return [points.first!, points.last!]
        }
    }

    private func perpendicularDistance(point: CLLocation, lineStart: CLLocation, lineEnd: CLLocation) -> Double {
        let a = lineStart.distance(from: point)
        let b = lineEnd.distance(from: point)
        let c = lineStart.distance(from: lineEnd)

        guard c > 0 else { return a }

        let s = (a + b + c) / 2
        let area = sqrt(max(0, s * (s - a) * (s - b) * (s - c)))
        return (2 * area) / c
    }

    // MARK: - Hausdorff Distance

    func hausdorffDistance(route1: [RoutePoint], route2: [RoutePoint]) -> Double {
        let d1 = directedHausdorff(from: route1, to: route2)
        let d2 = directedHausdorff(from: route2, to: route1)
        return max(d1, d2)
    }

    private func directedHausdorff(from source: [RoutePoint], to target: [RoutePoint]) -> Double {
        var maxMin: Double = 0
        for sp in source {
            var minDist = Double.greatestFiniteMagnitude
            for tp in target {
                let d = haversine(sp.coordinate, tp.coordinate)
                if d < minDist { minDist = d }
            }
            if minDist > maxMin { maxMin = minDist }
        }
        return maxMin
    }

    // MARK: - Haversine Distance (meters)

    func haversine(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        let R = 6371000.0
        let dLat = (c2.latitude - c1.latitude) * .pi / 180
        let dLon = (c2.longitude - c1.longitude) * .pi / 180
        let lat1 = c1.latitude * .pi / 180
        let lat2 = c2.latitude * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // MARK: - Route Matching

    func findMatchingCluster(for route: RouteRecord, in clusters: [RouteCluster]) -> RouteCluster? {
        let simplified = simplify(points: route.points)

        for cluster in clusters {
            guard let rep = RouteStore.shared.route(by: cluster.representativeRouteID) else { continue }
            let repSimplified = simplify(points: rep.points)
            let distance = hausdorffDistance(route1: simplified, route2: repSimplified)
            if distance < clusterThreshold {
                return cluster
            }
        }
        return nil
    }

    /// Check if a partial (live) route deviates from any known safe route
    func deviationDistance(livePoints: [RoutePoint], from cluster: RouteCluster) -> Double {
        guard let rep = RouteStore.shared.route(by: cluster.representativeRouteID) else {
            return Double.greatestFiniteMagnitude
        }
        let repSimplified = simplify(points: rep.points)
        return hausdorffDistance(route1: livePoints, route2: repSimplified)
    }
}
