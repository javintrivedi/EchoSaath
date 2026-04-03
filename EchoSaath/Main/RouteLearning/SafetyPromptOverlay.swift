import SwiftUI

struct SafetyPromptOverlay: View {
    @EnvironmentObject var processor: EventProcessor
    
    var body: some View {
        ZStack {
            // Dark transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.yellow)
                
                // Title
                Text("Route Change Detected")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                // Message
                Text("It looks like you are on a different path today. Is this your safe path?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        processor.resolveSafetyPrompt(isSafe: true)
                    } label: {
                        Text("Yes, I am Safe")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        processor.resolveSafetyPrompt(isSafe: false)
                    } label: {
                        Text("No, Notify Contacts")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Text("If no response, contacts will be notified automatically in 60s.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(32)
        }
    }
}

#Preview {
    SafetyPromptOverlay()
        .environmentObject(EventProcessor.shared)
}
