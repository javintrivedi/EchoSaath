import Foundation
import CoreLocation
import Combine

// MARK: - Route Tracker
final class RouteTracker: ObservableObject {
    static let shared = RouteTracker()

    @Published var status: RouteStatus = .idle
    @Published var currentRoutePoints: [RoutePoint] = []

    private var currentRoute: RouteRecord?
    private var lastStopLocation: CLLocation?
    private var lastMovementTime: Date = .now
    private var stationaryTimer: Timer?
    private let tripStartDistance: Double = 50     // meters to start a trip
    private let tripEndDuration: TimeInterval = 180 // 3 min stationary to end
    private let minPointDistance: Double = 10       // min meters between points

    private init() {}

    func startListening() {
        // Called from EventProcessor.init — tracker is now ready
    }

    func processLocation(_ location: CLLocation) {
        guard location.horizontalAccuracy < 50 else { return }  // filter bad GPS

        switch status {
        case .idle:
            handleIdle(location)
        case .tracking:
            handleTracking(location)
        case .analyzing:
            break
        }
    }

    // MARK: - Idle → Detect Trip Start
    private func handleIdle(_ location: CLLocation) {
        if let last = lastStopLocation {
            let distance = location.distance(from: last)
            if distance > tripStartDistance {
                startTrip(at: location)
            }
        }
        lastStopLocation = location
    }

    // MARK: - Tracking → Record Points
    private func handleTracking(_ location: CLLocation) {
        lastMovementTime = .now

        // Filter: only add point if moved enough
        if let lastPoint = currentRoutePoints.last {
            let distance = location.distance(from: lastPoint.clLocation)
            guard distance >= minPointDistance else { return }
        }

        let point = RoutePoint(location: location)
        currentRoutePoints.append(point)

        // Reset stationary timer
        stationaryTimer?.invalidate()
        stationaryTimer = Timer.scheduledTimer(withTimeInterval: tripEndDuration, repeats: false) { [weak self] _ in
            self?.endTrip()
        }

        // Live risk detection
        RouteRiskDetector.shared.checkLiveRoute(points: currentRoutePoints, currentLocation: location)
    }

    // MARK: - Trip Lifecycle
    private func startTrip(at location: CLLocation) {
        status = .tracking
        let point = RoutePoint(location: location)
        currentRoutePoints = [point]
        currentRoute = RouteRecord(points: [point], startTime: .now)

        stationaryTimer = Timer.scheduledTimer(withTimeInterval: tripEndDuration, repeats: false) { [weak self] _ in
            self?.endTrip()
        }
    }

    private func endTrip() {
        guard status == .tracking, currentRoutePoints.count >= 3 else {
            resetTracking()
            return
        }

        status = .analyzing
        stationaryTimer?.invalidate()

        var route = RouteRecord(
            points: currentRoutePoints,
            startTime: currentRoutePoints.first?.timestamp ?? .now,
            endTime: currentRoutePoints.last?.timestamp ?? .now
        )

        // Process in background
        PatternLearningEngine.shared.processCompletedRoute(route)
        if let lastPoint = currentRoutePoints.last {
            lastStopLocation = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
        }

        // Notify UI
        NotificationCenter.default.post(name: .routeDataUpdated, object: nil)

        resetTracking()
    }

    private func resetTracking() {
        status = .idle
        currentRoutePoints = []
        currentRoute = nil
        stationaryTimer?.invalidate()
    }
}

extension Notification.Name {
    static let routeDataUpdated = Notification.Name("routeDataUpdated")
}
