import SwiftUI
import CoreLocation
import AVFoundation
import Combine

class MonitoringSetupViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var micAuthorized: AVAudioSession.RecordPermission = .undetermined
    @Published var cameraAuthorized: AVAuthorizationStatus = .notDetermined
    @Published var backgroundRefreshEnabled: Bool = UIApplication.shared.backgroundRefreshStatus == .available
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        refreshStatuses()
    }
    
    func refreshStatuses() {
        locationStatus = locationManager.authorizationStatus
        micAuthorized = AVAudioSession.sharedInstance().recordPermission
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video)
        backgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            openAppSettings()
        }
    }
    
    func requestMicrophonePermission() {
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            openAppSettings()
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] _ in
                DispatchQueue.main.async { self?.refreshStatuses() }
            }
        }
    }
    
    func requestCameraPermission() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            openAppSettings()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async { self?.refreshStatuses() }
            }
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshStatuses()
    }
}
