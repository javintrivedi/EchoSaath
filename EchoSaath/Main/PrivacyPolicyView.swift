import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy & Safety")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Last updated: April 18, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // The "Local-First" Banner
                HStack(spacing: 15) {
                    Image(systemName: "hand.raised.shield.fill")
                        .font(.title)
                        .foregroundColor(.pink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local-First Philosophy")
                            .font(.headline)
                        Text("Your data never touches our servers. It stays on your device, where it belongs.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.pink.opacity(0.08))
                .cornerRadius(16)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    PrivacySectionCard(
                        icon: "lock.square.stack.fill",
                        title: "Data Collection",
                        content: "EchoSaath stores your medical profile, trusted contacts, and security history exclusively in your device's encrypted storage. We have zero access to this information.",
                        color: .purple
                    )
                    
                    PrivacySectionCard(
                        icon: "location.circle.fill",
                        title: "Location Privacy",
                        content: "Background location is used only for emergency detection and 'Route Learning'. This data is processed locally and is never uploaded or shared with third parties.",
                        color: .blue
                    )
                    
                    PrivacySectionCard(
                        icon: "bell.badge.fill",
                        title: "Emergency Alerts",
                        content: "When you trigger an SOS, your location and profile are sent via SMS/Email directly to your chosen contacts. This is the only time your data leaves your device.",
                        color: .red
                    )
                    
                    PrivacySectionCard(
                        icon: "waveform.path.ecg",
                        title: "Sensor Data",
                        content: "Motion data (accelerometer/gyroscope) is analyzed in real-time to detect falls or impacts. This data is temporary and is deleted immediately after processing.",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Contact Section
                VStack(spacing: 12) {
                    Text("Have questions?")
                        .font(.headline)
                    Text("We're here to help you stay safe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        if let url = URL(string: "mailto:javintrivedi007@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Contact Support")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
        .background(Color.appBackgroundPink.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySectionCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
