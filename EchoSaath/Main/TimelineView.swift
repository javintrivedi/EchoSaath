import SwiftUI
import CoreLocation

struct TimelineView: View {
    @EnvironmentObject var processor: EventProcessor

    @State private var query: String = ""
    @State private var selectedRisk: RiskLevel? = nil
    @State private var isRefreshing = false
    @State private var selectedTab: TimelineTab = .events

    private enum TimelineTab: String, CaseIterable {
        case events = "Events"
        case routeMap = "Route Map"
    }

    var body: some View {
        ZStack {
            Color.appBackgroundPink.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(TimelineTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if selectedTab == .routeMap {
                    RouteMapView()
                } else {
                    ScrollView {
                        if filteredAndGrouped.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                                ForEach(filteredAndGrouped.keys.sorted(by: >), id: \.self) { day in
                                    Section {
                                        ForEach(Array(filteredAndGrouped[day]!.enumerated()), id: \.1.id) { index, event in
                                            timelineRow(event: event, isLast: index == filteredAndGrouped[day]!.count - 1)
                                        }
                                    } header: {
                                        sectionHeader(day)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .refreshable {
                        isRefreshing = true
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isRefreshing = false
                    }
                    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search events")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        selectedRisk = nil
                    } label: {
                        HStack {
                            Text("All")
                            if selectedRisk == nil { Image(systemName: "checkmark") }
                        }
                    }

                    ForEach(RiskLevel.allCases, id: \.self) { level in
                        Button {
                            selectedRisk = level
                        } label: {
                            HStack {
                                Text(level.rawValue.capitalized)
                                if selectedRisk == level { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    Image(systemName: selectedRisk == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    processor.addTestEvent()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add test event")
            }
        }
        .navigationTitle("Timeline")
    }

    // MARK: - Timeline Row
    private func timelineRow(event: Event, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(dotColor(event.riskLevel).opacity(0.2))
                        .frame(width: 24, height: 24)
                    Circle()
                        .fill(dotColor(event.riskLevel))
                        .frame(width: 10, height: 10)
                }
                .padding(.top, 2)

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)

            // Content card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.reason)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Spacer()
                    riskBadge(event.riskLevel)
                }
                Text(event.timestamp.formatted(.dateTime.hour().minute().second()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }

    // MARK: - Section Header
    private func sectionHeader(_ day: Date) -> some View {
        HStack {
            Text(day.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView(
            label: {
                Label("No Events", systemImage: "clock.badge.questionmark")
            },
            description: {
                Text("Events from shake alerts, SOS triggers, and monitoring will appear here.")
            },
            actions: {
                Button {
                    processor.addTestEvent()
                } label: {
                    Label("Add Test Event", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers
    private func dotColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    private func riskBadge(_ level: RiskLevel) -> some View {
        Text(level.rawValue.uppercased())
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(dotColor(level)))
    }

    private var filtered: [Event] {
        let base = processor.recentEvents
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = q.isEmpty ? base : base.filter { $0.reason.localizedCaseInsensitiveContains(q) }
        if let selectedRisk {
            return searched.filter { $0.riskLevel == selectedRisk }
        }
        return searched
    }

    private var filteredAndGrouped: [Date: [Event]] {
        let cal = Calendar.current
        return Dictionary(grouping: filtered) { event in
            cal.startOfDay(for: event.timestamp)
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView()
            .environmentObject(EventProcessor.shared)
    }
}
