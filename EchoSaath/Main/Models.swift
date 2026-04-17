import Foundation
import CoreLocation
import SwiftUI

public enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case normal, elevated, critical
    
    public var color: Color {
        switch self {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }
}

public struct ProcessedEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let reason: String
    public let timestamp: Date
    public let riskLevel: RiskLevel
    public let latitude: Double?
    public let longitude: Double?

    public init(
        id: UUID = UUID(),
        reason: String,
        timestamp: Date = .now,
        riskLevel: RiskLevel,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.reason = reason
        self.timestamp = timestamp
        self.riskLevel = riskLevel
        self.latitude = latitude
        self.longitude = longitude
    }
}
