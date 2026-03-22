import SwiftUI

struct AppStartView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        if hasCompletedOnboarding {
            RootView()
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}

private struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var selection: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $selection) {
                    OnboardingPage(
                        title: "Welcome to EchoSaath",
                        subtitle: "Safety and support, always within reach.",
                        systemImage: "heart.circle.fill"
                    ).tag(0)

                    OnboardingPage(
                        title: "Background Monitoring",
                        subtitle: "Enable monitoring to detect emergencies and alert contacts.",
                        systemImage: "bolt.fill"
                    ).tag(1)

                    OnboardingPage(
                        title: "Stay Connected",
                        subtitle: "Add trusted contacts to notify when help is needed.",
                        systemImage: "person.2.fill"
                    ).tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(action: completeOnboarding) {
                    Text(selection < 2 ? "Next" : "Get Started")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
            )
            .navigationTitle("Getting Started")
        }
    }

    private func completeOnboarding() {
        if selection < 2 {
            selection += 1
        } else {
            hasCompletedOnboarding = true
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

#Preview {
    AppStartView()
}
