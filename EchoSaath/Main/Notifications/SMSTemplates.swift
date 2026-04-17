import Foundation
import CoreLocation

// MARK: - SMS Templates
enum SMSTemplates {
    enum AlertType: String {
        case sos = "SOS"
        case suspiciousActivity = "Suspicious Activity"
        case routeDeviation = "Route Deviation"
        case fallDetected = "Fall Detected"
        case unexpectedStop = "Unexpected Stop"
    }

    static func alertType(from reason: String) -> AlertType {
        let lowered = reason.lowercased()
        if lowered.contains("sos") || lowered.contains("shake") { return .sos }
        if lowered.contains("deviat") { return .routeDeviation }
        if lowered.contains("fall") { return .fallDetected }
        if lowered.contains("unexpected stop") || lowered.contains("unfamiliar") { return .unexpectedStop }
        return .suspiciousActivity
    }

    static func googleMapsLink(from location: CLLocation) -> String {
        "https://maps.google.com/?q=\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }

    static func buildPreviewMessage(userName: String, alertType: AlertType, location: CLLocation?, timestamp: Date = .now) -> String {
        let loc = location.map { googleMapsLink(from: $0) } ?? "Loc unavailable"
        let timeStr = timestamp.formatted(.dateTime.hour().minute())
        
        return "🚨EchoSaath \(alertType.rawValue): \(userName) needs help!\n📍:\(loc)\n🕐:\(timeStr)"
    }
}
