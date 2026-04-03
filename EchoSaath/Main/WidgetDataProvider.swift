import Foundation
import WidgetKit

/// Bridges data from the main app to the widget via App Group shared UserDefaults.
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    /// Must match the App Group configured in both targets' Signing & Capabilities.
    static let appGroupID = "group.jt.EchoSaath"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: WidgetDataProvider.appGroupID)
    }

    // MARK: - Keys
    private enum Key {
        static let isMonitoring       = "widget_isMonitoring"
        static let alertCount         = "widget_alertCount"
        static let contactCount       = "widget_contactCount"
        static let routeStatus        = "widget_routeStatus"
        static let lastEventReason    = "widget_lastEventReason"
        static let lastEventTime      = "widget_lastEventTime"
        static let lastEventRisk      = "widget_lastEventRisk"
        static let lastUpdated        = "widget_lastUpdated"
        static let userName           = "widget_userName"
    }

    // MARK: - Write (called from main app)

    /// Snapshots the current app state into shared defaults and reloads widget timelines.
    func updateWidgetData() {
        guard let defaults else { return }

        let processor = EventProcessor.shared
        let sensor = SensorManager.shared
        let contacts = TrustedContactsStore.shared
        let routeTracker = RouteTracker.shared

        // Monitoring status
        defaults.set(sensor.isMonitoring, forKey: Key.isMonitoring)

        // Today's alert count
        let cal = Calendar.current
        let alertCount = processor.recentEvents.filter {
            cal.isDateInToday($0.timestamp) &&
            ($0.riskLevel == .critical || $0.riskLevel == .elevated)
        }.count
        defaults.set(alertCount, forKey: Key.alertCount)

        // Trusted contacts count
        defaults.set(contacts.contacts.count, forKey: Key.contactCount)

        // Route tracking status
        let routeStatusString: String
        switch routeTracker.status {
        case .idle:      routeStatusString = "idle"
        case .tracking:  routeStatusString = "tracking"
        case .analyzing: routeStatusString = "analyzing"
        }
        defaults.set(routeStatusString, forKey: Key.routeStatus)

        // Last event info
        if let lastEvent = processor.recentEvents.first {
            defaults.set(lastEvent.reason, forKey: Key.lastEventReason)
            defaults.set(lastEvent.timestamp, forKey: Key.lastEventTime)
            defaults.set(lastEvent.riskLevel.rawValue, forKey: Key.lastEventRisk)
        }

        // User name
        defaults.set(AuthViewModel.shared.currentUserName, forKey: Key.userName)

        // Timestamp
        defaults.set(Date(), forKey: Key.lastUpdated)

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}
