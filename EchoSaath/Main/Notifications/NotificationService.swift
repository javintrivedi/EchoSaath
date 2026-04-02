import Foundation
import CoreLocation
import Combine

// MARK: - Notification Service
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isProcessing = false
    @Published var lastError: String?

    private let logger = NotificationLogger.shared
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = NotificationConfig.requestTimeout
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Welcome Email (SendGrid REST API)

    func sendWelcomeEmail(name: String, email: String) {
        let logID = logger.log(type: .welcomeEmail, recipient: email, recipientName: name, message: "Welcome email to \(name)")

        Task {
            do {
                let payload: [String: Any] = [
                    "personalizations": [["to": [["email": email, "name": name]]]],
                    "from": ["email": NotificationConfig.sendGridFromEmail, "name": NotificationConfig.sendGridFromName],
                    "subject": "Welcome to EchoSaath — Your Safety Companion 🛡️",
                    "content": [["type": "text/html", "value": Self.welcomeEmailHTML(name: name)]]
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)
                var request = URLRequest(url: NotificationConfig.sendGridMailURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(NotificationConfig.sendGridAPIKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = jsonData

                let (_, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw NotificationError.invalidResponse }

                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Welcome email sent to \(email)")
                    await MainActor.run { self.logger.markSent(id: logID) }
                } else {
                    throw NotificationError.serverError(statusCode: httpResponse.statusCode, message: "SendGrid rejected the request")
                }
            } catch {
                print("❌ Welcome email failed: \(error.localizedDescription)")
                await MainActor.run { self.logger.markFailed(id: logID, error: error.localizedDescription) }
            }
        }
    }

    private static func welcomeEmailHTML(name: String) -> String {
        """
        <div style="font-family:-apple-system,sans-serif;max-width:600px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
          <div style="background:linear-gradient(135deg,#EC4899,#8B5CF6);padding:40px 32px;text-align:center;">
            <h1 style="color:#fff;font-size:28px;margin:0;">🛡️ EchoSaath</h1>
            <p style="color:rgba(255,255,255,0.9);font-size:14px;margin:8px 0 0;">Your Safety Companion</p>
          </div>
          <div style="padding:32px;">
            <h2 style="color:#1F2937;font-size:22px;margin:0 0 16px;">Welcome, \(name)! 👋</h2>
            <p style="color:#4B5563;font-size:15px;line-height:1.6;">Thank you for joining <strong>EchoSaath</strong> — your personal safety monitoring application.</p>
            <h3 style="color:#1F2937;font-size:16px;">🔑 Key Features</h3>
            <div style="padding:12px;background:#FFF0F3;border-radius:12px;margin-bottom:8px;"><strong>🚨 SOS Alerts</strong><br><span style="color:#6B7280;">Hold the SOS button or shake your phone to alert trusted contacts instantly.</span></div>
            <div style="padding:12px;background:#F0FFF4;border-radius:12px;margin-bottom:8px;"><strong>📍 Route Learning</strong><br><span style="color:#6B7280;">Learns your frequent routes and alerts if you deviate from safe paths.</span></div>
            <div style="padding:12px;background:#EFF6FF;border-radius:12px;margin-bottom:8px;"><strong>📱 Background Monitoring</strong><br><span style="color:#6B7280;">Detects falls, sudden impacts, and unusual inactivity silently.</span></div>
            <h3 style="color:#1F2937;font-size:16px;">🚀 Getting Started</h3>
            <ol style="color:#4B5563;font-size:14px;line-height:1.8;"><li>Add your <strong>trusted contacts</strong></li><li>Enable <strong>location permissions</strong></li><li>Turn on <strong>monitoring</strong> in Settings</li><li>You're protected!</li></ol>
            <p style="color:#9CA3AF;font-size:13px;border-top:1px solid #E5E7EB;padding-top:16px;margin-top:24px;">Stay safe,<br><strong>The EchoSaath Team</strong></p>
          </div>
          <div style="background:#F9FAFB;padding:16px;text-align:center;"><p style="color:#9CA3AF;font-size:11px;margin:0;">© 2026 EchoSaath Safety App</p></div>
        </div>
        """
    }

    // MARK: - Emergency SMS (Direct Twilio REST API)

    func sendEmergencySMS(event: ProcessedEvent, location: CLLocation?, contacts: [TrustedContact]) {
        guard !contacts.isEmpty else { return }

        let alertType = SMSTemplates.alertType(from: event.reason)
        let userName = AuthViewModel.shared.currentUserName.isEmpty ? "EchoSaath User" : AuthViewModel.shared.currentUserName
        let smsBody = SMSTemplates.buildPreviewMessage(userName: userName, alertType: alertType, location: location, timestamp: event.timestamp)

        Task {
            await MainActor.run { self.isProcessing = true }
            for contact in contacts {
                let logID = logger.log(type: .emergencySMS, recipient: contact.phoneNumber, recipientName: contact.name, message: "\(alertType.rawValue) alert")
                await sendTwilioSMS(to: contact.phoneNumber, body: smsBody, logID: logID)
            }
            await MainActor.run { self.isProcessing = false }
        }
    }

    private func sendTwilioSMS(to phoneNumber: String, body: String, logID: UUID) async {
        let normalizedPhone = normalizePhoneNumber(phoneNumber)

        for attempt in 1...NotificationConfig.maxRetryAttempts {
            do {
                let formBody = ["From": NotificationConfig.twilioFromNumber, "To": normalizedPhone, "Body": body]
                let formString = formBody.map { "\($0.key)=\(percentEncode($0.value))" }.joined(separator: "&")

                var request = URLRequest(url: NotificationConfig.twilioSMSURL)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = formString.data(using: .utf8)

                let credentials = "\(NotificationConfig.twilioAccountSID):\(NotificationConfig.twilioAuthToken)"
                request.setValue("Basic \(Data(credentials.utf8).base64EncodedString())", forHTTPHeaderField: "Authorization")

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw NotificationError.invalidResponse }

                if (200...299).contains(httpResponse.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let sid = json["sid"] as? String {
                        print("✅ SMS sent to \(normalizedPhone) — SID: \(sid)")
                    }
                    await MainActor.run { self.logger.markSent(id: logID); self.lastError = nil }
                    return
                } else {
                    let errorMessage: String
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = json["message"] as? String { errorMessage = msg } else { errorMessage = "HTTP \(httpResponse.statusCode)" }
                    throw NotificationError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            } catch {
                print("⚠️ SMS attempt \(attempt)/\(NotificationConfig.maxRetryAttempts) failed for \(normalizedPhone): \(error.localizedDescription)")
                if attempt < NotificationConfig.maxRetryAttempts {
                    let delay = NotificationConfig.retryBaseDelay * pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    await MainActor.run { self.logger.markFailed(id: logID, error: error.localizedDescription); self.lastError = error.localizedDescription }
                }
            }
        }
    }

    // MARK: - Retry

    func retryNotification(_ entry: NotificationLogEntry) {
        logger.incrementRetry(id: entry.id)
        switch entry.type {
        case .welcomeEmail: sendWelcomeEmail(name: entry.recipientName, email: entry.recipient)
        case .emergencySMS:
            let contact = TrustedContact(name: entry.recipientName, phoneNumber: entry.recipient)
            sendEmergencySMS(event: ProcessedEvent(reason: entry.message, riskLevel: .critical), location: SensorManager.shared.currentLocation, contacts: [contact])
        }
    }

    func retryAllFailed() { logger.logs.filter { $0.status == .failed }.forEach { retryNotification($0) } }

    // MARK: - Helpers

    private func normalizePhoneNumber(_ phone: String) -> String {
        var cleaned = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if cleaned.hasPrefix("+") { return cleaned }
        if cleaned.hasPrefix("0") { return "+91\(String(cleaned.dropFirst()))" }
        let digits = cleaned.filter { $0.isNumber }
        if digits.count == 10 { return "+91\(digits)" }
        if !cleaned.hasPrefix("+") { cleaned = "+\(cleaned)" }
        return cleaned
    }

    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed; allowed.remove(charactersIn: "+&=")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}

// MARK: - Errors
enum NotificationError: LocalizedError {
    case invalidResponse, serverError(statusCode: Int, message: String), invalidJSON, apiError(message: String)
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .invalidJSON: return "Could not parse server response"
        case .apiError(let msg): return msg
        }
    }
}
