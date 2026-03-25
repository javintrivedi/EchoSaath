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
                AlertsView()
            }
            .tabItem {
                Label("Alerts", systemImage: "bell.fill")
            }
            .badge(alertBadgeCount)

            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.fill")
            }

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
    }

    private var alertBadgeCount: Int {
        processor.recentEvents.filter { $0.riskLevel == .critical || $0.riskLevel == .elevated }.count
    }
}

#Preview {
    MainTabView()
}
