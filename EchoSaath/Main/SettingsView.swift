import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var authVM = AuthViewModel.shared
    @ObservedObject var sensorManager = SensorManager.shared
    @AppStorage("enableMonitoring") private var enableMonitoring: Bool = true
    @AppStorage("shakeSensitivity") private var shakeSensitivity: Double = 2.7
    @AppStorage("shakeToAlert") private var shakeToAlert: Bool = true
    @State private var showingResetConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var exportURL: URL?
    @State private var isPreparingExport = false

    var body: some View {
        Form {
            // MARK: - Profile Section
            Section {
                HStack(spacing: 14) {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(String(authVM.currentUserName.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authVM.currentUserName.isEmpty ? "User" : authVM.currentUserName)
                            .font(.headline)
                        Text(authVM.currentUserEmail.isEmpty ? "No email" : authVM.currentUserEmail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                
                NavigationLink(destination: ProfileSetupView()) {
                    Label("Medical & Physical Profile", systemImage: "heart.text.square.fill")
                }
            }

            // MARK: - Monitoring
            Section("Monitoring") {
                Toggle("Enable Live Monitoring", isOn: $enableMonitoring)
                    .onChange(of: enableMonitoring) { _, newValue in
                        if newValue {
                            SensorManager.shared.startMonitoring()
                        } else {
                            SensorManager.shared.stopMonitoring()
                        }
                    }

                HStack {
                    Label("Status", systemImage: sensorManager.isMonitoring ? "bolt.fill" : "bolt.slash")
                        .foregroundStyle(sensorManager.isMonitoring ? .green : .secondary)
                    Spacer()
                    Text(sensorManager.isMonitoring ? "Active" : "Inactive")
                        .foregroundStyle(sensorManager.isMonitoring ? .green : .secondary)
                        .font(.callout)
                }
            }

            // MARK: - Safety Features
            Section("Safety Features") {
                Toggle("Shake to Send Alert", isOn: $shakeToAlert)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Shake Sensitivity")
                        Spacer()
                        Text(String(format: "%.1f", shakeSensitivity))
                            .foregroundStyle(.secondary)
                            .font(.callout.monospacedDigit())
                    }
                    Slider(value: $shakeSensitivity, in: 1.5...4.0, step: 0.1)
                        .tint(.pink)
                    HStack {
                        Text("More Sensitive")
                            .font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text("Less Sensitive")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Contacts
            Section("Contacts") {
                NavigationLink(destination: TrustedContactsView(isOnboarding: false)) {
                    Label("Trusted Contacts", systemImage: "person.2.fill")
                        .badge(TrustedContactsStore.shared.contacts.count)
                }
            }

            // MARK: - Notifications
            Section("Notifications") {
                Button {
                    requestNotificationPermission()
                } label: {
                    Label("Review Notification Permission", systemImage: "bell.badge")
                }

                NavigationLink(destination: NotificationLogView()) {
                    Label("Notification Log", systemImage: "list.bullet.rectangle")
                        .badge(NotificationLogger.shared.failedCount)
                }
            }

            // MARK: - Debug & Support
            Section("Debug & Support") {
                Button {
                    EventProcessor.shared.addTestEvent()
                } label: {
                    Label("Trigger Test Event", systemImage: "play.fill")
                }

                Button {
                    sendTestNotification()
                } label: {
                    Label("Send Test Notification", systemImage: "bell")
                }

                Button {
                    exportLogs()
                } label: {
                    Label(isPreparingExport ? "Preparing..." : "Export Logs", systemImage: "square.and.arrow.up")
                }
                .disabled(isPreparingExport)

                if let exportURL {
                    ShareLink(item: exportURL, preview: .init("EchoSaath Export")) {
                        Label("Share Export File", systemImage: "doc.text")
                    }
                }
            }

            // MARK: - Data
            Section("Data") {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset All Data", systemImage: "trash")
                }
            }

            // MARK: - Account
            Section {
                Button(role: .destructive) {
                    showingLogoutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }

            // MARK: - Footer
            Section(footer: Text("EchoSaath v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") • Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")) {
                EmptyView()
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all monitoring data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                SensorManager.shared.stopMonitoring()
                EventProcessor.shared.clearAllEvents()
                enableMonitoring = false
            }
        } message: {
            Text("This will clear all events and stop monitoring. This cannot be undone.")
        }
        .confirmationDialog("Log out of EchoSaath?", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                SensorManager.shared.stopMonitoring()
                authVM.logout()
            }
        }
        .onAppear {
            if enableMonitoring && !sensorManager.isMonitoring {
                SensorManager.shared.startMonitoring()
            }
        }
    }

    // MARK: - Helpers
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendTestNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "EchoSaath Test"
            content.body = "Test notification successful! 🎉"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func exportLogs() {
        isPreparingExport = true
        var lines: [String] = []
        lines.append("EchoSaath Export - \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")
        lines.append("User: \(authVM.currentUserName) (\(authVM.currentUserEmail))")
        lines.append("")
        lines.append("Settings:")
        lines.append("  Monitoring: \(enableMonitoring ? "Active" : "Inactive")")
        lines.append("  Shake Sensitivity: \(String(format: "%.1f", shakeSensitivity))")
        lines.append("  Shake to Alert: \(shakeToAlert ? "On" : "Off")")
        lines.append("  Contacts: \(TrustedContactsStore.shared.contacts.count)")
        lines.append("")
        lines.append("Recent Events (\(EventProcessor.shared.recentEvents.count)):")
        EventProcessor.shared.recentEvents.prefix(20).enumerated().forEach { index, event in
            lines.append("  \(index + 1). \(event.reason) [\(event.riskLevel.rawValue.uppercased())] - \(event.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
        }

        let text = lines.joined(separator: "\n")
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("EchoSaath_Export_\(Int(Date().timeIntervalSince1970)).txt")
        do {
            try text.data(using: .utf8)?.write(to: tmp)
            DispatchQueue.main.async {
                self.exportURL = tmp
                self.isPreparingExport = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isPreparingExport = false
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
