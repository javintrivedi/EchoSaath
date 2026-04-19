import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var authVM = AuthViewModel.shared
    @ObservedObject var sensorManager = SensorManager.shared
    @AppStorage("enableMonitoring") private var enableMonitoring: Bool = true
    @AppStorage("shakeSensitivity") private var shakeSensitivity: Double = 2.7
    @AppStorage("shakeToAlert") private var shakeToAlert: Bool = true
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("alertCountdownDuration") private var alertCountdownDuration: Int = 10
    @State private var showingResetConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var exportURL: URL?
    @State private var isPreparingExport = false

    var body: some View {
        ZStack {
            Color.appBackgroundPink
                .ignoresSafeArea()
            
            Form {
                // MARK: - Profile Section
                Section {
                    HStack(spacing: 14) {
                        if let data = UserProfileStore.shared.profile.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        } else {
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
                        }

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
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Monitoring
                Section("Monitoring") {
                    Toggle("Enable Live Monitoring", isOn: $enableMonitoring)
                        .tint(.green)
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
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Safety Features
                Section("Safety Features") {
                    Toggle("Shake to Send Alert", isOn: $shakeToAlert)
                        .tint(.green)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Shake Sensitivity")
                            Spacer()
                            Text(String(format: "%.1f", shakeSensitivity))
                                .foregroundStyle(.secondary)
                                .font(.callout.monospacedDigit())
                        }
                        Slider(value: $shakeSensitivity, in: 1.5...4.0, step: 0.1)
                            .tint(.green)
                        HStack {
                            Text("More Sensitive")
                                .font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("Less Sensitive")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("SOS Countdown")
                            Spacer()
                            Text("\(alertCountdownDuration)s")
                                .foregroundStyle(.secondary)
                        }
                        Picker("Countdown Duration", selection: $alertCountdownDuration) {
                            Text("5s").tag(5)
                            Text("10s").tag(10)
                            Text("20s").tag(20)
                            Text("30s").tag(30)
                        }
                        .pickerStyle(.segmented)
                        .tint(.green)
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))
                
                // MARK: - Safety Intelligence
                Section("Safety Intelligence") {
                    HStack {
                        Label("Current Risk Level", systemImage: "shield.lefthalf.filled")
                        Spacer()
                        Text(EventProcessor.shared.currentRisk.rawValue.capitalized)
                            .foregroundStyle(EventProcessor.shared.currentRisk.color)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Label("Current Risk Score", systemImage: "gauge.with.needle")
                        Spacer()
                        Text("\(Int(EventProcessor.shared.currentRiskScore))%")
                            .foregroundStyle(EventProcessor.shared.currentRisk.color)
                            .font(.callout.monospacedDigit())
                    }
                    
                    HStack {
                        Label("Route Learning", systemImage: "brain.head.profile")
                        Spacer()
                        Text(RouteRiskDetector.shared.learningProgress)
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Contacts
                Section("Contacts") {
                    NavigationLink(destination: TrustedContactsView(isOnboarding: false)) {
                        Label("Trusted Contacts", systemImage: "person.2.fill")
                            .badge(TrustedContactsStore.shared.contacts.count)
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

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
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

            #if DEBUG
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
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))
            #endif

                // MARK: - About
            Section("About") {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "lock.shield")
                }
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            }
            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

            // MARK: - Data
                Section("Data") {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Account
                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8))

                // MARK: - Footer
                Section(footer: Text("EchoSaath v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") • Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")) {
                    EmptyView()
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all monitoring data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                SensorManager.shared.stopMonitoring()
                EventProcessor.shared.clearAllEvents()
                RouteStore.shared.clearAll()
                RouteRiskDetector.shared.resetLearning()
                TrustedContactsStore.shared.clearAll()
                UserProfileStore.shared.resetProfile()
                NotificationLogger.shared.clearAll()
                enableMonitoring = false
                // Wipe credentials and send user back to the start
                AuthViewModel.shared.fullReset()
            }
        } message: {
            Text("This will erase ALL data — events, routes, contacts, your profile, and your account. The app will restart from scratch. This cannot be undone.")
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
