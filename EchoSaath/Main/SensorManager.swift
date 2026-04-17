import CoreLocation
import CoreMotion
import Combine
import Foundation
import WidgetKit

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SensorManager()

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()

    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var isMonitoring: Bool = false
    @Published var riskLevelString: String = "normal"

    let eventPublisher = PassthroughSubject<SensorEvent, Never>()

    private var shakeThreshold: Double {
        UserDefaults.standard.object(forKey: "shakeSensitivity") as? Double ?? 2.7
    }

    // Debounce: prevent multiple shake triggers in quick succession
    private var lastShakeTime: Date = .distantPast
    private let shakeCooldown: TimeInterval = 3.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 15
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        let status = locationManager.authorizationStatus
        if status == .notDetermined || status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
        
        // Optimize for background power
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = false
        
        // Initial state: Balanced power
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // Only update every 50 meters normally
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges() // Low power fallback
        startMotionDetection()
        WidgetDataProvider.shared.updateWidgetData()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingHeading()
        motionManager.stopAccelerometerUpdates()
        WidgetDataProvider.shared.updateWidgetData()
    }

    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable, !motionManager.isAccelerometerActive else { return }
        
        // Default interval: 0.2s (Efficient)
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            
            let magnitude = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )

            // Dynamic Power Scaling:
            // If movement is detected, increase GPS accuracy
            if magnitude > 1.2 {
                if self.locationManager.desiredAccuracy != kCLLocationAccuracyBest {
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                    self.locationManager.distanceFilter = 10
                }
            } else {
                // If stationary for a while, downshift GPS to save battery
                if self.locationManager.desiredAccuracy != kCLLocationAccuracyHundredMeters {
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
                    self.locationManager.distanceFilter = 50
                }
            }

            // Shake / sudden impact detection
            if magnitude > self.shakeThreshold {
                let now = Date()
                guard now.timeIntervalSince(self.lastShakeTime) >= self.shakeCooldown else { return }
                self.lastShakeTime = now
                self.eventPublisher.send(.suddenMotion(magnitude: magnitude))
            }
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        eventPublisher.send(.locationUpdate(location))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        } else if status == .authorizedWhenInUse {
            locationManager.allowsBackgroundLocationUpdates = false
        }
    }
}

enum SensorEvent {
    case locationUpdate(CLLocation)
    case suddenMotion(magnitude: Double)
    case deviceStationary(duration: TimeInterval)
}
