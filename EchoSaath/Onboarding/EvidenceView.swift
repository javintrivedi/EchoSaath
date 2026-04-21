import SwiftUI

struct EvidenceView: View {
    @State private var appear = false
    @State private var nextPressed = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles with subtle motion
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
                VStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.pink)
                        .padding(14)
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .opacity(0.15)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Always Watching Over You")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("EchoSaath silently monitors your safety using your phone's sensors — no camera or microphone needed.")
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

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "location.fill", title: "Live location tracking", subtitle: "Continuously monitors your GPS to detect route deviations.")
                    featureRow(icon: "waveform.path.ecg", title: "Shake-to-SOS", subtitle: "Detects sudden impact or shake gesture to trigger an alert.")
                    featureRow(icon: "envelope.fill", title: "Instant SMS alerts", subtitle: "Notifies trusted contacts with your location the moment SOS fires.")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Spacer(minLength: 0)

                NavigationLink(destination: ControlView()) {
                    HStack(spacing: 8) {
                        Text("Next")
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
                    .scaleEffect(nextPressed ? 0.98 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: nextPressed)
                    .accessibilityLabel("Continue to the next step")
                    .accessibilityHint("Learn how you stay in control")
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear { appear = true }
        }
        .navigationTitle("How It Works")
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
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
