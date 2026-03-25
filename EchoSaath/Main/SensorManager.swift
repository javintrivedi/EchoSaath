import CoreLocation
import CoreMotion
import Combine
import Foundation

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = SensorManager()

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()

    @Published var currentLocation: CLLocation?
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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        locationManager.requestWhenInUseAuthorization()

        // Only enable background location after authorization is in place
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }

        locationManager.startUpdatingLocation()
        startMotionDetection()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        locationManager.stopUpdatingLocation()
        motionManager.stopAccelerometerUpdates()
    }

    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable, !motionManager.isAccelerometerActive else { return }
        motionManager.accelerometerUpdateInterval = 0.15
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let magnitude = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )

            // Shake / sudden impact detection with threshold from settings
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
}

enum SensorEvent {
    case locationUpdate(CLLocation)
    case suddenMotion(magnitude: Double)
    case deviceStationary(duration: TimeInterval)
}
