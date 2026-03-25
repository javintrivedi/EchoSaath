import Foundation

enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case normal, elevated, critical
}

struct ProcessedEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let reason: String
    let timestamp: Date
    let riskLevel: RiskLevel

    init(id: UUID = UUID(), reason: String, timestamp: Date = .now, riskLevel: RiskLevel) {
        self.id = id
        self.reason = reason
        self.timestamp = timestamp
        self.riskLevel = riskLevel
    }
}

struct Event: Identifiable, Equatable {
    let id: UUID
    let reason: String
    let timestamp: Date
    let riskLevel: RiskLevel

    init(id: UUID = UUID(), reason: String, timestamp: Date = .now, riskLevel: RiskLevel) {
        self.id = id
        self.reason = reason
        self.timestamp = timestamp
        self.riskLevel = riskLevel
    }
}
