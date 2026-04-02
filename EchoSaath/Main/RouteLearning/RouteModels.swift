import Foundation
import CoreLocation

// MARK: - Route Point
struct RoutePoint: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double       // m/s
    let accuracy: Double    // meters

    init(id: UUID = UUID(), location: CLLocation) {
        self.id = id
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = max(0, location.speed)
        self.accuracy = location.horizontalAccuracy
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Route Record
struct RouteRecord: Codable, Identifiable {
    let id: UUID
    var points: [RoutePoint]
    let startTime: Date
    var endTime: Date
    var classification: RouteClassification
    var clusterID: UUID?
    var userMarkedSafe: Bool

    init(
        id: UUID = UUID(),
        points: [RoutePoint] = [],
        startTime: Date = .now,
        endTime: Date = .now,
        classification: RouteClassification = .unusual,
        clusterID: UUID? = nil,
        userMarkedSafe: Bool = false
    ) {
        self.id = id
        self.points = points
        self.startTime = startTime
        self.endTime = endTime
        self.classification = classification
        self.clusterID = clusterID
        self.userMarkedSafe = userMarkedSafe
    }

    var durationMinutes: Double {
        endTime.timeIntervalSince(startTime) / 60.0
    }

    var distanceMeters: Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0
        for i in 1..<points.count {
            total += points[i].clLocation.distance(from: points[i - 1].clLocation)
        }
        return total
    }
}

// MARK: - Route Cluster
struct RouteCluster: Codable, Identifiable {
    let id: UUID
    var routeIDs: [UUID]
    var representativeRouteID: UUID
    var classification: RouteClassification
    var frequency: Int
    var lastUsed: Date
    var timeOfDayPattern: [Int] // hours when this route is typically used

    init(
        id: UUID = UUID(),
        routeIDs: [UUID] = [],
        representativeRouteID: UUID = UUID(),
        classification: RouteClassification = .unusual,
        frequency: Int = 1,
        lastUsed: Date = .now,
        timeOfDayPattern: [Int] = []
    ) {
        self.id = id
        self.routeIDs = routeIDs
        self.representativeRouteID = representativeRouteID
        self.classification = classification
        self.frequency = frequency
        self.lastUsed = lastUsed
        self.timeOfDayPattern = timeOfDayPattern
    }
}

// MARK: - Classification
enum RouteClassification: String, Codable, CaseIterable {
    case safe = "Safe"
    case usual = "Usual"
    case unusual = "Unusual"

    var color: String {
        switch self {
        case .safe: return "green"
        case .usual: return "blue"
        case .unusual: return "orange"
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .usual: return "arrow.triangle.swap"
        case .unusual: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Route Status
enum RouteStatus {
    case idle
    case tracking
    case analyzing
}
