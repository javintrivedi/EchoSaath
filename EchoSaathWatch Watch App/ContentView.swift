import SwiftUI
import WatchConnectivity
import Combine

// 1. Create a simple manager to handle the connection
class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var isAlerting = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                triggerSOS()
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                        .frame(width: 120, height: 120)
                        .shadow(radius: 5)
                    
                    VStack(spacing: 2) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.title2)
                        Text("SOS")
                            .font(.system(size: 20, weight: .black))
                    }
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            Text(isAlerting ? "SOS SENT!" : "Tap to Alert")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isAlerting ? .red : .secondary)
        }
    }
    
    func triggerSOS() {
        // Play a "failure" haptic on the watch (feels like a double-tap)
        WKInterfaceDevice.current().play(.failure)
        
        // Ensure session is active before sending
        if WCSession.default.activationState == .activated {
            WCSession.default.sendMessage(["action": "triggerSOS"], replyHandler: nil) { error in
                print("Error sending SOS: \(error.localizedDescription)")
            }
            
            withAnimation {
                isAlerting = true
            }
            
            // Reset status after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isAlerting = false
            }
        } else {
            // Re-activate if it somehow disconnected
            WCSession.default.activate()
        }
    }
}
