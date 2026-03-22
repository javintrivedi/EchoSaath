//
//  MonitoringSetupView.swift
//  EchoSaath
//
//  Created by Javin Trivedi on 11/03/26.
//

import SwiftUI
import CoreLocation
import AVFoundation
import Photos

struct MonitoringSetupView: View {

    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var micAuthorized: AVAudioSession.RecordPermission = .undetermined
    @State private var cameraAuthorized: AVAuthorizationStatus = .notDetermined
    @State private var backgroundRefreshEnabled: Bool = UIApplication.shared.backgroundRefreshStatus == .available
    @State private var requesting: Bool = false

    private let locationDelegate = LocationDelegate()
    private let locationManager = CLLocationManager()

    init() {
        // Configure location manager delegate
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
                    Text("Activate Background Monitoring")
                        .font(.largeTitle.bold())
                    Text("Enable these features to allow EchoSaath to detect emergencies.")
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
                    MonitoringCard(title: "Location Monitoring", icon: "location.fill", status: readableLocationStatus(locationStatus)) {
                        requestLocationPermission()
                    }

                    MonitoringCard(title: "Audio Detection", icon: "mic.fill", status: readableMicStatus(micAuthorized)) {
                        requestMicrophonePermission()
                    }

                    MonitoringCard(title: "Camera Recording", icon: "video.fill", status: readableCameraStatus(cameraAuthorized)) {
                        requestCameraPermission()
                    }

                    MonitoringCard(title: "Background Monitoring", icon: "bolt.fill", status: backgroundRefreshEnabled ? "Enabled" : "Disabled") {
                        openBackgroundSettings()
                    }
                }

                Spacer()

                NavigationLink(destination: TrustedContactsView()) {
                    Text("Continue")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear(perform: refreshStatuses)
        .navigationTitle("Setup Monitoring")
    }

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

    private func openBackgroundSettings() {
        // Direct toggling isn't allowed; guide user to Settings
        openAppSettings()
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func readableLocationStatus(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func readableMicStatus(_ status: AVAudioSession.RecordPermission) -> String {
        switch status {
        case .granted: return "Allowed"
        case .denied: return "Denied"
        case .undetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func readableCameraStatus(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Allowed"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
}

struct MonitoringCard: View {
    let title: String
    let icon: String
    var status: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) permission")
        .accessibilityHint("Tap to request access")
    }
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {}
