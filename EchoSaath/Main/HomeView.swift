import SwiftUI

struct HomeView: View {
    @EnvironmentObject var processor: EventProcessor
    @ObservedObject var authVM = AuthViewModel.shared
    @ObservedObject var sensorManager = SensorManager.shared
    @State private var sosProgress: CGFloat = 0
    @State private var isSosActive = false
    @State private var sosTimer: Timer?
    @State private var pulseAnimation = false

    private var todayEventCount: Int {
        let cal = Calendar.current
        return processor.recentEvents.filter { cal.isDateInToday($0.timestamp) }.count
    }

    private var alertCount: Int {
        processor.recentEvents.filter { $0.riskLevel == .critical || $0.riskLevel == .elevated }.count
    }

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.94, blue: 0.96)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Text(authVM.currentUserName.isEmpty ? "Stay safe" : "Stay safe, \(authVM.currentUserName.components(separatedBy: " ").first ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Profile avatar
                        Circle()
                            .fill(
                                LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(authVM.currentUserName.prefix(1)).uppercased())
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                            )
                    }
                    .padding(.horizontal)

                    // Status card
                    statusCard
                        .padding(.horizontal)

                    // Stat cards row
                    HStack(spacing: 12) {
                        statCard(
                            icon: "person.2.fill",
                            color: .blue,
                            title: "Contacts",
                            value: "\(TrustedContactsStore.shared.contacts.count)"
                        )
                        statCard(
                            icon: "bell.badge.fill",
                            color: .orange,
                            title: "Alerts Today",
                            value: "\(alertCount)"
                        )
                        statCard(
                            icon: "clock.fill",
                            color: .purple,
                            title: "Events",
                            value: "\(todayEventCount)"
                        )
                    }
                    .padding(.horizontal)

                    // SOS Button
                    sosButton
                        .padding(.horizontal)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            quickActionCard(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Shake Alert",
                                subtitle: UserDefaults.standard.object(forKey: "shakeToAlert") as? Bool ?? true ? "Enabled" : "Disabled",
                                color: .green
                            )
                            quickActionCard(
                                icon: "waveform",
                                title: "Monitoring",
                                subtitle: sensorManager.isMonitoring ? "Active" : "Paused",
                                color: sensorManager.isMonitoring ? .green : .gray
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("EchoSaath")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Status Card
    private var statusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(sensorManager.isMonitoring ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 60, height: 60)

                if sensorManager.isMonitoring {
                    Circle()
                        .fill(Color.green.opacity(0.08))
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                }

                Image(systemName: sensorManager.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(sensorManager.isMonitoring ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sensorManager.isMonitoring ? "Protection Active" : "Protection Paused")
                    .font(.title3.bold())
                    .foregroundStyle(sensorManager.isMonitoring ? .green : .red)
                Text(sensorManager.isMonitoring
                     ? "Background monitoring is running silently."
                     : "Enable monitoring in Settings to stay protected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .onAppear { pulseAnimation = true }
    }

    // MARK: - SOS Button
    private var sosButton: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.red.opacity(0.15), lineWidth: 8)
                    .frame(width: 130, height: 130)

                // Progress ring
                Circle()
                    .trim(from: 0, to: sosProgress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: sosProgress)

                // Button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSosActive ? [.red, .orange] : [.red.opacity(0.9), .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: .red.opacity(0.4), radius: isSosActive ? 20 : 10, x: 0, y: 4)
                    .scaleEffect(isSosActive ? 0.95 : 1.0)

                VStack(spacing: 2) {
                    Image(systemName: "sos")
                        .font(.system(size: 28, weight: .heavy))
                    Text("HOLD 3s")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in startSOS() }
                    .onEnded { _ in cancelSOS() }
            )

            Text("Press & hold for emergency SOS")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }

    // MARK: - SOS Logic
    private func startSOS() {
        guard !isSosActive else { return }
        isSosActive = true
        sosProgress = 0

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        sosTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            sosProgress += 0.05 / 3.0 // 3 seconds total
            if sosProgress >= 1.0 {
                timer.invalidate()
                sosTimer = nil
                triggerSOS()
            }
        }
    }

    private func cancelSOS() {
        sosTimer?.invalidate()
        sosTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            isSosActive = false
            sosProgress = 0
        }
    }

    private func triggerSOS() {
        // Strong haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        processor.triggerManualSOS()
        withAnimation(.easeOut(duration: 0.3)) {
            isSosActive = false
            sosProgress = 0
        }
    }

    // MARK: - Helper Views
    private func statCard(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 6)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌆"
        default: return "Good Night 🌙"
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(EventProcessor.shared)
    }
}
