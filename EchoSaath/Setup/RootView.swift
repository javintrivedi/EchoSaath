import SwiftUI

struct RootView: View {
    @State private var isAuthenticated: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if isAuthenticated {
                    MonitoringSetupView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    AuthFlowContainer(isAuthenticated: $isAuthenticated)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: isAuthenticated)
        }
    }
}

private struct AuthFlowContainer: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        AuthView()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Temporary: simulate successful login/signup
                    Button("Skip") { isAuthenticated = true }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didAuthenticate)) { _ in
                isAuthenticated = true
            }
    }
}

extension Notification.Name {
    static let didAuthenticate = Notification.Name("didAuthenticate")
}

#Preview {
    RootView()
}
