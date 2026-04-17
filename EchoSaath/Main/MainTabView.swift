import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var processor: EventProcessor

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                SecurityHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.badge.exclamationmark.fill")
            }
            .badge(alertBadgeCount)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(.pink)
        .onAppear {
            let enableMonitoring = UserDefaults.standard.object(forKey: "enableMonitoring") as? Bool ?? true
            if enableMonitoring {
                SensorManager.shared.startMonitoring()
            }
        }
        .fullScreenCover(isPresented: $processor.isCountingDown) {
            EmergencyCountdownView()
        }
        .overlay {
            if processor.showSafetyPrompt {
                SafetyPromptOverlay()
                    .zIndex(90)
            }
        }
    }

    private var alertBadgeCount: Int {
        processor.recentEvents.filter { $0.riskLevel == .critical || $0.riskLevel == .elevated }.count
    }
}

#Preview {
    MainTabView()
}
