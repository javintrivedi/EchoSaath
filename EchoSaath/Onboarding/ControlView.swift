import SwiftUI

struct ControlView: View {
    @State private var appear = false
    @State private var continuePressed = false
    
    var body: some View {
        ZStack {
            // Background gradient (same as EvidenceView)
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles with subtle motion (same behavior)
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .offset(x: -120 + (appear ? -6 : 0), y: -260 + (appear ? -4 : 0))
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: appear)
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .offset(x: 140 + (appear ? 6 : 0), y: 240 + (appear ? 4 : 0))
                        .animation(.easeInOut(duration: 1.2).delay(0.2).repeatForever(autoreverses: true), value: appear)
                }
                .frame(width: size.width, height: size.height, alignment: .center)
            }
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Card with icon and headings (mirrors EvidenceView style)
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.pink)
                        .padding(14)
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .opacity(0.15)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("You Stay in Control")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Only your trusted contacts receive alerts. Your privacy remains protected.")
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

                // Optional feature rows for Control (mirroring EvidenceView structure)
                VStack(alignment: .leading, spacing: 12) {
                    controlFeatureRow(icon: "person.2.fill", title: "Trusted contacts", subtitle: "Choose who gets notified during SOS.")
                    controlFeatureRow(icon: "lock.fill", title: "Privacy first", subtitle: "Your data is protected and under your control.")
                    controlFeatureRow(icon: "hand.tap.fill", title: "Easy controls", subtitle: "Pause notifications or stop SOS anytime.")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Spacer(minLength: 0)

                NavigationLink(destination: MonitoringSetupView()) {
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
                    .scaleEffect(continuePressed ? 0.98 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: continuePressed)
                    .accessibilityLabel("Continue to monitoring setup")
                    .accessibilityHint("Configure how alerts are sent")
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear { appear = true }
        }
        .navigationTitle("Control")
    }
    
    @ViewBuilder
    private func controlFeatureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.pink)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
    }
}
