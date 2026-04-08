import SwiftUI

struct NotificationLogView: View {
    @ObservedObject var logger = NotificationLogger.shared
    @ObservedObject var service = NotificationService.shared

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.94, blue: 0.96).ignoresSafeArea()
            if logger.logs.isEmpty {
                ContentUnavailableView(label: { Label("No Notifications", systemImage: "bell.slash") }, description: { Text("Sent emails and SMS alerts will appear here.") })
            } else {
                ScrollView {
                    summaryBanner.padding(.horizontal).padding(.top, 8)
                    LazyVStack(spacing: 10) { ForEach(logger.recentLogs) { entry in logCard(entry) } }.padding(.horizontal).padding(.bottom)
                }
            }
        }
        .navigationTitle("Notification Log")
        .toolbar {
            if !logger.logs.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if logger.failedCount > 0 { Button { service.retryAllFailed() } label: { Label("Retry All Failed", systemImage: "arrow.clockwise") } }
                        Button(role: .destructive) { logger.clearAll() } label: { Label("Clear Log", systemImage: "trash") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
    }

    private var summaryBanner: some View {
        HStack(spacing: 16) {
            summaryItem(count: logger.logs.filter { $0.status == .sent }.count, label: "Sent", color: .green, icon: "checkmark.circle.fill")
            summaryItem(count: logger.pendingCount, label: "Pending", color: .orange, icon: "clock.fill")
            summaryItem(count: logger.failedCount, label: "Failed", color: .red, icon: "xmark.circle.fill")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3))
    }

    private func summaryItem(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text("\(count)").font(.title3.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }

    private func logCard(_ entry: NotificationLogEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(typeColor(entry).opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: entry.type == .welcomeEmail ? "envelope.fill" : "message.fill").font(.system(size: 18, weight: .semibold)).foregroundColor(typeColor(entry))
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.type.rawValue).font(.subheadline.bold())
                    Spacer()
                    statusBadge(entry.status)
                }
                Text(entry.recipientName.isEmpty ? entry.recipient : "\(entry.recipientName) · \(entry.recipient.suffix(4))").font(.caption).foregroundColor(.secondary).lineLimit(1)
                HStack {
                    Text(entry.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute())).font(.caption2).foregroundColor(.secondary)
                    if entry.retryCount > 0 { Text("· \(entry.retryCount) retries").font(.caption2).foregroundColor(.orange) }
                }
                if let error = entry.errorMessage, entry.status == .failed { Text(error).font(.caption2).foregroundColor(.red).lineLimit(2) }
            }
            if entry.status == .failed {
                Button { service.retryNotification(entry) } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .semibold)).foregroundColor(.blue).frame(width: 32, height: 32).background(Color.blue.opacity(0.1)).clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .secondarySystemGroupedBackground)).shadow(color: statusColor(entry.status).opacity(0.08), radius: 6, x: 0, y: 2))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(statusColor(entry.status).opacity(0.15), lineWidth: 1))
    }

    private func statusBadge(_ status: NotificationLogEntry.DeliveryStatus) -> some View {
        HStack(spacing: 3) { Circle().fill(statusColor(status)).frame(width: 6, height: 6); Text(status.rawValue).font(.system(size: 9, weight: .heavy)).foregroundColor(statusColor(status)) }
            .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(statusColor(status).opacity(0.12)))
    }

    private func statusColor(_ status: NotificationLogEntry.DeliveryStatus) -> Color { switch status { case .sent: return .green; case .pending: return .orange; case .failed: return .red } }
    private func typeColor(_ entry: NotificationLogEntry) -> Color { entry.type == .welcomeEmail ? .blue : .red }
}

#Preview { NavigationStack { NotificationLogView() } }
