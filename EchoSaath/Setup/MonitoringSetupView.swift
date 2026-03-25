import SwiftUI
import CoreLocation
import AVFoundation

struct MonitoringSetupView: View {

    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var micAuthorized: AVAudioSession.RecordPermission = AVAudioSession.RecordPermission.undetermined
    @State private var cameraAuthorized: AVAuthorizationStatus = .notDetermined
    @State private var backgroundRefreshEnabled: Bool = UIApplication.shared.backgroundRefreshStatus == .available

    private let locationDelegate = LocationDelegate()
    private let locationManager = CLLocationManager()

    init() {
        locationManager.delegate = locationDelegate
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.bottom, 4)

                    Text("Activate Monitoring")
                        .font(.largeTitle.bold())

                    Text("Enable these permissions so EchoSaath can protect you in emergencies.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

                VStack(spacing: 12) {
                    MonitoringCard(title: "Location", icon: "location.fill", status: readableLocationStatus(locationStatus)) {
                        requestLocationPermission()
                    }

                    MonitoringCard(title: "Microphone", icon: "mic.fill", status: readableMicStatus(micAuthorized)) {
                        requestMicrophonePermission()
                    }

                    MonitoringCard(title: "Camera", icon: "video.fill", status: readableCameraStatus(cameraAuthorized)) {
                        requestCameraPermission()
                    }

                    MonitoringCard(title: "Background Refresh", icon: "bolt.fill", status: backgroundRefreshEnabled ? "Enabled" : "Disabled") {
                        openAppSettings()
                    }
                }

                Spacer()

                NavigationLink(destination: TrustedContactsView(isOnboarding: true)) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .pink.opacity(0.25), radius: 10, x: 0, y: 8)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear(perform: refreshStatuses)
        .navigationTitle("Setup Monitoring")
    }

    // MARK: - Permission Logic
    private func refreshStatuses() {
        locationStatus = locationManager.authorizationStatus
        micAuthorized = AVAudioSession.sharedInstance().recordPermission
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video)
        backgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
    }

    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            openAppSettings()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { refreshStatuses() }
    }

    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            DispatchQueue.main.async { refreshStatuses() }
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { refreshStatuses() }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func readableLocationStatus(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Always ✓"
        case .authorizedWhenInUse: return "When In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }

    private func readableMicStatus(_ status: AVAudioSession.RecordPermission) -> String {
        switch status {
        case .granted: return "Allowed ✓"
        case .denied: return "Denied"
        case .undetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }

    private func readableCameraStatus(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Allowed ✓"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }
}

struct MonitoringCard: View {
    let title: String
    let icon: String
    var status: String
    var action: () -> Void

    private var isGranted: Bool {
        status.contains("✓") || status == "Enabled"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(isGranted ? .green : .secondary)
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isGranted ? Color.green.opacity(0.3) : Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {}
