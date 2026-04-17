import Foundation
import CoreLocation
import Combine

// MARK: - Notification Service
class NotificationService: ObservableObject {
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
        let logID = logger.log(
            type: .welcomeEmail,
            recipient: email,
            recipientName: name,
            message: "Welcome email to \(name)"
        )

        Task {
            do {
                let payload: [String: Any] = [
                    "personalizations": [["to": [["email": email, "name": name]]]],
                    "from": ["email": NotificationConfig.sendGridFromEmail, "name": NotificationConfig.sendGridFromName],
                    "subject": "Welcome to EchoSaath",
                    "content": [["type": "text/html", "value": Self.welcomeEmailHTML(name: name)]]
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)
                var request = URLRequest(url: NotificationConfig.sendGridMailURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(NotificationConfig.sendGridAPIKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = jsonData

                let (_, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { 
                    throw NotificationError.invalidResponse 
                }

                if (200...299).contains(httpResponse.statusCode) {
                    await MainActor.run { 
                        self.logger.markSent(id: logID) 
                    }
                } else {
                    throw NotificationError.serverError(statusCode: httpResponse.statusCode, message: "SendGrid rejected the request")
                }
            } catch {
                await MainActor.run { 
                    self.logger.markFailed(id: logID, error: error.localizedDescription) 
                }
            }
        }
    }

    private static func welcomeEmailHTML(name: String) -> String {
        """
        <div style="font-family:sans-serif;max-width:600px;margin:20px auto;padding:20px;border:1px solid #eee;border-radius:10px;">
            <h2 style="color:#EC4899;">Welcome to EchoSaath, \(name)!</h2>
            <p>Your account is now active and protected.</p>
            <p><strong>Next Steps:</strong></p>
            <ul>
                <li>Add your trusted contacts in the app.</li>
                <li>Enable background monitoring for fall and impact detection.</li>
                <li>Try a "Test SOS" to see the alert system in action.</li>
            </ul>
            <p style="color:#666;font-size:12px;margin-top:30px;">Stay safe,<br>The EchoSaath Team</p>
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
                let logID = logger.log(
                    type: .emergencySMS, 
                    recipient: contact.phoneNumber, 
                    recipientName: contact.name, 
                    message: "\(alertType.rawValue) alert"
                )
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
                let base64Creds = Data(credentials.utf8).base64EncodedString()
                request.setValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw NotificationError.invalidResponse }

                if (200...299).contains(httpResponse.statusCode) {
                    await MainActor.run { 
                        self.logger.markSent(id: logID)
                        self.lastError = nil 
                    }
                    return
                } else {
                    let errorMessage: String
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], 
                       let msg = json["message"] as? String { 
                        errorMessage = msg 
                    } else { 
                        errorMessage = "HTTP \(httpResponse.statusCode)" 
                    }
                    throw NotificationError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            } catch {
                if attempt < NotificationConfig.maxRetryAttempts {
                    let delay = NotificationConfig.retryBaseDelay * pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    await MainActor.run { 
                        self.logger.markFailed(id: logID, error: error.localizedDescription)
                        self.lastError = error.localizedDescription 
                    }
                }
            }
        }
    }

    // MARK: - Retry

    func retryNotification(_ entry: NotificationLogEntry) {
        logger.incrementRetry(id: entry.id)
        switch entry.type {
        case .welcomeEmail: 
            sendWelcomeEmail(name: entry.recipientName, email: entry.recipient)
        case .emergencySMS:
            let contact = TrustedContact(name: entry.recipientName, phoneNumber: entry.recipient)
            let event = ProcessedEvent(
                reason: entry.message, 
                riskLevel: .critical,
                latitude: SensorManager.shared.currentLocation?.coordinate.latitude,
                longitude: SensorManager.shared.currentLocation?.coordinate.longitude
            )
            sendEmergencySMS(event: event, location: SensorManager.shared.currentLocation, contacts: [contact])
        }
    }

    func retryAllFailed() { 
        logger.logs.filter { $0.status == .failed }.forEach { retryNotification($0) } 
    }

    // MARK: - Helpers

    private func normalizePhoneNumber(_ phone: String) -> String {
        var cleaned = phone.replacingOccurrences(of: " ", with: "")
                           .replacingOccurrences(of: "-", with: "")
                           .replacingOccurrences(of: "(", with: "")
                           .replacingOccurrences(of: ")", with: "")
        if cleaned.hasPrefix("+") { return cleaned }
        if cleaned.hasPrefix("0") { return "+91\(String(cleaned.dropFirst()))" }
        let digits = cleaned.filter { $0.isNumber }
        if digits.count == 10 { return "+91\(digits)" }
        if !cleaned.hasPrefix("+") { cleaned = "+\(cleaned)" }
        return cleaned
    }

    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}

// MARK: - Errors
enum NotificationError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case invalidJSON
    case apiError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .invalidJSON: return "Could not parse server response"
        case .apiError(let msg): return msg
        }
    }
}
