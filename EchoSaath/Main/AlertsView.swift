import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var processor: EventProcessor

    private var alerts: [Event] {
        processor.recentEvents.filter { $0.riskLevel == .elevated || $0.riskLevel == .critical }
    }

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.94, blue: 0.96).ignoresSafeArea()

            if alerts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(alerts) { alert in
                            alertCard(alert)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding()
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: alerts.count)
                }
            }
        }
        .navigationTitle("Alerts")
        .toolbar {
            if !alerts.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            for alert in alerts {
                                processor.resolveEvent(id: alert.id)
                            }
                        }
                    } label: {
                        Text("Clear All")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                    )
            }

            Text("All Clear")
                .font(.title2.bold())

            Text("No alerts right now.\nShake your phone or press the SOS button\nto trigger an emergency alert.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                processor.triggerManualSOS()
            } label: {
                Label("Test SOS Alert", systemImage: "exclamationmark.triangle.fill")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Alert Card
    private func alertCard(_ event: Event) -> some View {
        HStack(spacing: 14) {
            // Risk indicator
            ZStack {
                Circle()
                    .fill(riskColor(event.riskLevel).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: riskIcon(event.riskLevel))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(riskColor(event.riskLevel))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.reason)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Spacer()
                    riskBadge(event.riskLevel)
                }

                Text(event.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: riskColor(event.riskLevel).opacity(0.1), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(riskColor(event.riskLevel).opacity(0.2), lineWidth: 1)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { processor.resolveEvent(id: event.id) }
            } label: {
                Label("Dismiss", systemImage: "xmark.circle")
            }
        }
        .contextMenu {
            Button {
                withAnimation { processor.resolveEvent(id: event.id) }
            } label: {
                Label("Dismiss Alert", systemImage: "xmark.circle")
            }
        }
    }

    // MARK: - Helpers
    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    private func riskIcon(_ level: RiskLevel) -> String {
        switch level {
        case .normal: return "info.circle.fill"
        case .elevated: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    private func riskBadge(_ level: RiskLevel) -> some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(riskColor(level))
            )
    }
}

#Preview {
    NavigationStack {
        AlertsView()
            .environmentObject(EventProcessor.shared)
    }
}
