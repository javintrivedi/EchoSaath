import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct WelcomeOnboardingView: View {
    @State private var currentStep = 0
    @AppStorage("hasSeenWelcomeOnboarding") private var hasSeenWelcomeOnboarding = false
    @Environment(\.dismiss) var dismiss
    
    let steps = [
        OnboardingStep(
            title: "Your Silent Guardian",
            description: "EchoSaath runs in the background, monitoring your safety using advanced motion and route intelligence.",
            icon: "shield.lefthalf.filled",
            color: .pink
        ),
        OnboardingStep(
            title: "Shake for SOS",
            description: "In immediate danger? Just shake your phone vigorously to trigger a 10-second countdown before sending SOS alerts.",
            icon: "iphone.radiowaves.left.and.right",
            color: .purple
        ),
        OnboardingStep(
            title: "Route Intelligence",
            description: "The app learns your frequent paths over 10 days. If you stray too far from a safe route, we'll check in on you.",
            icon: "brain.head.profile",
            color: .blue
        ),
        OnboardingStep(
            title: "Zero Data Sharing",
            description: "Your location and medical profile are stored locally on your device. Only your trusted contacts see them during an alert.",
            icon: "lock.shield.fill",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            Color.appBackgroundPink.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            Image(systemName: steps[index].icon)
                                .font(.system(size: 100))
                                .foregroundStyle(
                                    LinearGradient(colors: [steps[index].color, steps[index].color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(height: 150)
                            
                            VStack(spacing: 16) {
                                Text(steps[index].title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                
                                Text(steps[index].description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
                
                Button {
                    if currentStep < steps.count - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasSeenWelcomeOnboarding = true
        }
        dismiss()
    }
}

#Preview {
    WelcomeOnboardingView()
}
