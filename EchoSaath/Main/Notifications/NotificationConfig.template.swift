import Foundation

// MARK: - Notification Configuration Template
// COPY THIS TO NotificationConfig.swift AND FILL IN YOUR CREDENTIALS
enum NotificationConfigTemplate {

    // ─── Twilio Credentials (SMS) ───────────────────────────
    static let twilioAccountSID = "YOUR_TWILIO_SID"
    static let twilioAuthToken  = "YOUR_TWILIO_AUTH_TOKEN"
    static let twilioFromNumber = "YOUR_TWILIO_PHONE_NUMBER"

    /// Twilio SMS API endpoint
    static var twilioSMSURL: URL {
        URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(twilioAccountSID)/Messages.json")!
    }

    // ─── SendGrid Credentials (Email) ───────────────────────
    static let sendGridAPIKey    = "YOUR_SENDGRID_API_KEY"
    static let sendGridFromEmail = "YOUR_SENDER_EMAIL"
    static let sendGridFromName  = "EchoSaath Safety"

    /// SendGrid Mail API endpoint
    static var sendGridMailURL: URL {
        URL(string: "https://api.sendgrid.com/v3/mail/send")!
    }

    // ─── Retry Configuration ────────────────────────────────
    static let maxRetryAttempts = 1
    static let retryBaseDelay: TimeInterval = 2.0

    // ─── Request Configuration ──────────────────────────────
    static let requestTimeout: TimeInterval = 15.0
}
