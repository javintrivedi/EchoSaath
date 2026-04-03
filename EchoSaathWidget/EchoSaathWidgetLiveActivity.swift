//
//  EchoSaathWidgetLiveActivity.swift
//  EchoSaathWidget
//
//  Created by Javin Trivedi on 03/04/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EchoSaathWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String          // "monitoring", "alert", "sos"
        var eventReason: String
        var riskLevel: String       // "normal", "elevated", "critical"
    }

    var userName: String
}

struct EchoSaathWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EchoSaathWidgetAttributes.self) { context in
            // Lock screen/banner UI
            HStack(spacing: 12) {
                Image(systemName: statusIcon(for: context.state.status))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(statusColor(for: context.state.riskLevel))
                    .frame(width: 40, height: 40)
                    .background(statusColor(for: context.state.riskLevel).opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("EchoSaath")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(context.state.eventReason)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(statusLabel(for: context.state.status))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor(for: context.state.riskLevel))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor(for: context.state.riskLevel).opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(16)
            .activityBackgroundTint(Color(.systemBackground))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: statusIcon(for: context.state.status))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(statusColor(for: context.state.riskLevel))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(statusLabel(for: context.state.status))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor(for: context.state.riskLevel))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.eventReason)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: statusIcon(for: context.state.status))
                    .foregroundStyle(statusColor(for: context.state.riskLevel))
            } compactTrailing: {
                Text(statusLabel(for: context.state.status))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor(for: context.state.riskLevel))
            } minimal: {
                Image(systemName: statusIcon(for: context.state.status))
                    .foregroundStyle(statusColor(for: context.state.riskLevel))
            }
            .keylineTint(statusColor(for: context.state.riskLevel))
        }
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "alert": return "exclamationmark.triangle.fill"
        case "sos":   return "sos"
        default:      return "checkmark.shield.fill"
        }
    }

    private func statusLabel(for status: String) -> String {
        switch status {
        case "alert": return "Alert"
        case "sos":   return "SOS"
        default:      return "Active"
        }
    }

    private func statusColor(for riskLevel: String) -> Color {
        switch riskLevel {
        case "critical": return .red
        case "elevated": return .orange
        default:         return .green
        }
    }
}

extension EchoSaathWidgetAttributes {
    fileprivate static var preview: EchoSaathWidgetAttributes {
        EchoSaathWidgetAttributes(userName: "Javin")
    }
}

extension EchoSaathWidgetAttributes.ContentState {
    fileprivate static var monitoring: EchoSaathWidgetAttributes.ContentState {
        EchoSaathWidgetAttributes.ContentState(status: "monitoring", eventReason: "All systems active", riskLevel: "normal")
    }

    fileprivate static var alert: EchoSaathWidgetAttributes.ContentState {
        EchoSaathWidgetAttributes.ContentState(status: "alert", eventReason: "Fall detected", riskLevel: "critical")
    }
}

#Preview("Notification", as: .content, using: EchoSaathWidgetAttributes.preview) {
    EchoSaathWidgetLiveActivity()
} contentStates: {
    EchoSaathWidgetAttributes.ContentState.monitoring
    EchoSaathWidgetAttributes.ContentState.alert
}
