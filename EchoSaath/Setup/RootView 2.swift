import SwiftUI

struct RootHomePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Welcome Home")
                    .font(.title2).bold()
                Text("This is the app's root screen. Replace this with your real home/dashboard view.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .navigationTitle("Home")
        }
    }
}

#Preview {
    RootHomePlaceholderView()
}
