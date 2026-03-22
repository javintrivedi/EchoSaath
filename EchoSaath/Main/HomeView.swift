import SwiftUI

struct HomeView: View {
    
    var body: some View {
        TabView {
            ZStack {
                Color(red: 1.0, green: 0.94, blue: 0.96)
                    .ignoresSafeArea()
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Top status card
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                                .overlay {
                                    HStack(spacing: 16) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 40, weight: .semibold))
                                            .foregroundColor(.green)
                                            .padding(10)
                                            .background(
                                                Circle()
                                                    .fill(Color.green.opacity(0.15))
                                            )
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Monitoring Active")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.green)
                                                .fontDesign(.serif)
                                            Text("Your background protection is running silently.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .padding(.horizontal)
                            
                            // Three small cards
                            HStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Image(systemName: "map.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Route Learning:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("ACTIVE")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "icloud.slash")
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                    Text("Offline Mode:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("READY")
                                        .fontWeight(.bold)
                                        .foregroundColor(.yellow)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    Text("Last Sync:")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("2 min ago")
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            TimelineView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    HomeView()
}
