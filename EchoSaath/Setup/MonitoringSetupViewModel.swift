import SwiftUI
import CoreLocation
import Combine

class MonitoringSetupViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var backgroundRefreshEnabled: Bool = UIApplication.shared.backgroundRefreshStatus == .available
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        refreshStatuses()
    }
    
    func refreshStatuses() {
        locationStatus = locationManager.authorizationStatus
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
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshStatuses()
    }
}
