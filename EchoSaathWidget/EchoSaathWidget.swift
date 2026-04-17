//
//  EchoSaathWidget.swift
//  EchoSaathWidget
//
//  Created by Javin Trivedi on 03/04/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Reader
struct WidgetData {
    let isMonitoring: Bool
    let alertCount: Int
    let contactCount: Int
    let routeStatus: String
    let lastEventReason: String
    let lastEventTime: Date?
    let lastEventRisk: String
    let userName: String
    let lastUpdated: Date?

    static let placeholder = WidgetData(
        isMonitoring: true,
        alertCount: 0,
        contactCount: 3,
        routeStatus: "idle",
        lastEventReason: "All clear",
        lastEventTime: nil,
        lastEventRisk: "normal",
        userName: "User",
        lastUpdated: nil
    )

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.jt.EchoSaath") else {
            return .placeholder
        }

        return WidgetData(
            isMonitoring: defaults.bool(forKey: "widget_isMonitoring"),
            alertCount: defaults.integer(forKey: "widget_alertCount"),
            contactCount: defaults.integer(forKey: "widget_contactCount"),
            routeStatus: defaults.string(forKey: "widget_routeStatus") ?? "idle",
            lastEventReason: defaults.string(forKey: "widget_lastEventReason") ?? "No events yet",
            lastEventTime: defaults.object(forKey: "widget_lastEventTime") as? Date,
            lastEventRisk: defaults.string(forKey: "widget_lastEventRisk") ?? "normal",
            userName: defaults.string(forKey: "widget_userName") ?? "User",
            lastUpdated: defaults.object(forKey: "widget_lastUpdated") as? Date
        )
    }
}

// MARK: - Timeline Entry
struct EchoSaathEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let data: WidgetData
}

// MARK: - Timeline Provider
struct EchoSaathTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EchoSaathEntry {
        EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> EchoSaathEntry {
        EchoSaathEntry(date: .now, configuration: configuration, data: WidgetData.load())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<EchoSaathEntry> {
        let entry = EchoSaathEntry(date: .now, configuration: configuration, data: WidgetData.load())
        // Refresh every 15 minutes if the app doesn't push updates sooner
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Widget Definition
struct EchoSaathWidget: Widget {
    let kind: String = "EchoSaathWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: EchoSaathTimelineProvider()) { entry in
            EchoSaathWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("EchoSaath")
        .description("Your safety status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Lock Screen Widget
struct EchoSaathLockScreenWidget: Widget {
    let kind: String = "EchoSaathLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: EchoSaathTimelineProvider()) { entry in
            EchoSaathWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("EchoSaath Lock Screen")
        .description("Safety status on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Entry View Router
struct EchoSaathWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: EchoSaathEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        case .accessoryCircular:
            AccessoryCircularView(data: entry.data)
        case .accessoryRectangular:
            AccessoryRectangularView(data: entry.data)
        case .accessoryInline:
            AccessoryInlineView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(spacing: 10) {
            // Status icon
            ZStack {
                Circle()
                    .fill(
                        data.isMonitoring
                            ? Color.green.opacity(0.15)
                            : Color.red.opacity(0.15)
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: data.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(data.isMonitoring ? .green : .red)
            }

            VStack(spacing: 2) {
                Text(data.isMonitoring ? "Protected" : "Paused")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(data.isMonitoring ? .green : .red)

                Text("EchoSaath")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Alert badge if any
            if data.alertCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 10))
                    Text("\(data.alertCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 14) {
            // Left: Status indicator
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            data.isMonitoring
                                ? Color.green.opacity(0.15)
                                : Color.red.opacity(0.15)
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: data.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(data.isMonitoring ? .green : .red)
                }

                Text(data.isMonitoring ? "Active" : "Paused")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(data.isMonitoring ? .green : .red)
            }
            .frame(width: 72)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1.5)
                .padding(.vertical, 8)

            // Right: Stats grid
            VStack(spacing: 10) {
                HStack(spacing: 16) {
                    statItem(
                        icon: "person.2.fill",
                        value: "\(data.contactCount)",
                        label: "Contacts",
                        color: .blue
                    )
                    statItem(
                        icon: "bell.badge.fill",
                        value: "\(data.alertCount)",
                        label: "Alerts",
                        color: .orange
                    )
                    statItem(
                        icon: routeIcon,
                        value: routeLabel,
                        label: "Route",
                        color: routeColor
                    )
                }

                // Last updated
                if let updated = data.lastUpdated {
                    Text("Updated \(updated, style: .relative) ago")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var routeIcon: String {
        switch data.routeStatus {
        case "tracking":  return "location.fill"
        case "analyzing": return "brain.head.profile.fill"
        default:          return "location.slash"
        }
    }

    private var routeLabel: String {
        switch data.routeStatus {
        case "tracking":  return "Live"
        case "analyzing": return "Busy"
        default:          return "Idle"
        }
    }

    private var routeColor: Color {
        switch data.routeStatus {
        case "tracking":  return .green
        case "analyzing": return .purple
        default:          return .gray
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EchoSaath")
                        .font(.system(size: 17, weight: .bold, design: .rounded))

                    Text(greetingText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(data.isMonitoring ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(data.isMonitoring ? "Protected" : "Paused")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(data.isMonitoring ? .green : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (data.isMonitoring ? Color.green : Color.red).opacity(0.12)
                )
                .clipShape(Capsule())
            }
            .padding(.bottom, 12)

            // Stats row
            HStack(spacing: 0) {
                largeStat(
                    icon: "person.2.fill",
                    value: "\(data.contactCount)",
                    label: "Contacts",
                    color: .blue
                )
                largeStat(
                    icon: "bell.badge.fill",
                    value: "\(data.alertCount)",
                    label: "Alerts Today",
                    color: .orange
                )
                largeStat(
                    icon: routeIcon,
                    value: routeLabel,
                    label: "Route",
                    color: routeColor
                )
            }
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.bottom, 12)

            // Last event card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: eventIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(eventColor)
                    Text("Last Event")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let eventTime = data.lastEventTime {
                        Text(eventTime, style: .relative)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Text("ago")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(data.lastEventReason)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(eventColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(eventColor.opacity(0.15), lineWidth: 1)
            )

            Spacer(minLength: 4)

            // Footer
            if let updated = data.lastUpdated {
                Text("Updated \(updated, style: .relative) ago")
                    .font(.system(size: 9))
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func largeStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var routeIcon: String {
        switch data.routeStatus {
        case "tracking":  return "location.fill"
        case "analyzing": return "brain.head.profile.fill"
        default:          return "location.slash"
        }
    }

    private var routeLabel: String {
        switch data.routeStatus {
        case "tracking":  return "Live"
        case "analyzing": return "Busy"
        default:          return "Idle"
        }
    }

    private var routeColor: Color {
        switch data.routeStatus {
        case "tracking":  return .green
        case "analyzing": return .purple
        default:          return .gray
        }
    }

    private var eventIcon: String {
        switch data.lastEventRisk {
        case "critical": return "exclamationmark.triangle.fill"
        case "elevated": return "exclamationmark.circle.fill"
        default:         return "info.circle.fill"
        }
    }

    private var eventColor: Color {
        switch data.lastEventRisk {
        case "critical": return .red
        case "elevated": return .orange
        default:         return .blue
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌆"
        default:      return "Good Night 🌙"
        }
    }
}

// MARK: - Accessory Circular
struct AccessoryCircularView: View {
    let data: WidgetData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: data.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(data.isMonitoring ? .green : .red)
        }
    }
}

// MARK: - Accessory Rectangular
struct AccessoryRectangularView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: data.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundStyle(data.isMonitoring ? .green : .red)
                    .imageScale(.small)
                Text("EchoSaath")
                    .font(.headline)
                    .widgetAccentable()
            }
            
            Text(data.isMonitoring ? "System Active" : "Tracking Paused")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if data.alertCount > 0 {
                Label("\(data.alertCount) Alerts", systemImage: "bell.badge.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                Text("All systems clear")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Accessory Inline
struct AccessoryInlineView: View {
    let data: WidgetData

    var body: some View {
        HStack {
            Image(systemName: data.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
            Text("EchoSaath: \(data.isMonitoring ? "Protected" : "Paused")")
        }
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: WidgetData(
        isMonitoring: false, alertCount: 2, contactCount: 1,
        routeStatus: "tracking", lastEventReason: "Shake SOS triggered!",
        lastEventTime: .now, lastEventRisk: "critical", userName: "Javin",
        lastUpdated: .now
    ))
}

#Preview("Medium", as: .systemMedium) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: WidgetData(
        isMonitoring: true, alertCount: 1, contactCount: 3,
        routeStatus: "tracking", lastEventReason: "🚨 Shake SOS triggered!",
        lastEventTime: Date().addingTimeInterval(-120), lastEventRisk: "critical",
        userName: "Javin", lastUpdated: .now
    ))
}

#Preview("Circular", as: .accessoryCircular) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: WidgetData(
        isMonitoring: false, alertCount: 0, contactCount: 3,
        routeStatus: "idle", lastEventReason: "Paused",
        lastEventTime: nil, lastEventRisk: "normal", userName: "Javin",
        lastUpdated: .now
    ))
}

#Preview("Rectangular", as: .accessoryRectangular) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: WidgetData(
        isMonitoring: true, alertCount: 3, contactCount: 3,
        routeStatus: "tracking", lastEventReason: "Elevated risk detected",
        lastEventTime: .now, lastEventRisk: "elevated", userName: "Javin",
        lastUpdated: .now
    ))
}

#Preview("Inline", as: .accessoryInline) {
    EchoSaathWidget()
} timeline: {
    EchoSaathEntry(date: .now, configuration: ConfigurationAppIntent(), data: .placeholder)
}
