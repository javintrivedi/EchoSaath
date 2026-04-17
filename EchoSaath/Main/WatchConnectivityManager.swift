import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var lastMessage: String = ""
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func sendEmergencyTrigger() {
        let message: [String: Any] = ["action": "triggerSOS", "reason": "Triggered from Apple Watch"]
        sendMessage(message)
    }
    
    func updateWatchRisk(level: String, score: Double) {
        let message: [String: Any] = ["action": "updateRisk", "level": level, "score": score]
        sendMessage(message)
    }
    
    private func sendMessage(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Watch connectivity error: \(error.localizedDescription)")
            }
        } else {
            // If watch is not reachable, try updating application context for later
            try? WCSession.default.updateApplicationContext(message)
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                if action == "triggerSOS" {
                    EventProcessor.shared.triggerManualSOS()
                }
            }
        }
    }
}
