import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenWelcomeOnboarding") private var hasSeenWelcomeOnboarding = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @ObservedObject private var authVM = AuthViewModel.shared

    var body: some View {
        Group {
            if !hasSeenWelcomeOnboarding {
                WelcomeOnboardingView()
            } else if !hasCompletedOnboarding {
                // Step 1: Onboarding flow
                OnboardingFlowView()
            } else if !authVM.isLoggedIn {
                // Step 2: Authentication
                NavigationStack {
                    AuthView()
                }
            } else if !authVM.hasCompletedProfile {
                // Step 3: Profile Setup
                NavigationStack {
                    ProfileSetupView()
                }
            } else {
                // Step 4: Main app
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: authVM.isLoggedIn)
        .animation(.easeInOut(duration: 0.35), value: authVM.hasCompletedProfile)
        .preferredColorScheme(appTheme.colorScheme)
    }
}

// MARK: - Onboarding Flow Container
struct OnboardingFlowView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}

#Preview {
    RootView()
}
