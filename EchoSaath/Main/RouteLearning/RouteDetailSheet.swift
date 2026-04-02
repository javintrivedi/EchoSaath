import SwiftUI

// MARK: - Route Detail Sheet
struct RouteDetailSheet: View {
    let route: RouteRecord
    @Environment(\.dismiss) private var dismiss
    @State private var clusters: [RouteCluster] = []

    private var cluster: RouteCluster? {
        guard let cid = route.clusterID else { return nil }
        return clusters.first { $0.id == cid }
    }

    var body: some View {
        NavigationStack {
            List {
                // Classification
                Section {
                    HStack {
                        Image(systemName: route.classification.icon)
                            .font(.title2)
                            .foregroundColor(classColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.classification.rawValue)
                                .font(.headline)
                                .foregroundColor(classColor)
                            Text(classDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }

                // Stats
                Section("Trip Details") {
                    LabeledContent("Date", value: route.startTime.formatted(.dateTime.month(.abbreviated).day().year()))
                    LabeledContent("Time", value: "\(route.startTime.formatted(.dateTime.hour().minute())) → \(route.endTime.formatted(.dateTime.hour().minute()))")
                    LabeledContent("Duration", value: String(format: "%.0f min", route.durationMinutes))
                    LabeledContent("Distance", value: String(format: "%.0f m", route.distanceMeters))
                    LabeledContent("Points recorded", value: "\(route.points.count)")
                }

                // Cluster info
                if let cluster = cluster {
                    Section("Pattern Info") {
                        LabeledContent("Times traveled", value: "\(cluster.frequency)")
                        LabeledContent("Last used", value: cluster.lastUsed.formatted(.dateTime.month(.abbreviated).day()))
                        if !cluster.timeOfDayPattern.isEmpty {
                            LabeledContent("Usual hours") {
                                Text(cluster.timeOfDayPattern.sorted().map { "\($0):00" }.joined(separator: ", "))
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Actions
                Section {
                    if route.classification != .safe {
                        Button {
                            markAsSafe()
                        } label: {
                            Label("Mark as Safe Route", systemImage: "checkmark.shield")
                                .foregroundColor(.green)
                        }
                    }

                    Button(role: .destructive) {
                        deleteRoute()
                    } label: {
                        Label("Delete Route", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                clusters = RouteStore.shared.loadClusters()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var classColor: Color {
        switch route.classification {
        case .safe: return .green
        case .usual: return .blue
        case .unusual: return .orange
        }
    }

    private var classDescription: String {
        switch route.classification {
        case .safe: return "This route is recognized as safe and frequently traveled."
        case .usual: return "This route has been traveled several times."
        case .unusual: return "This is a new or infrequent route."
        }
    }

    private func markAsSafe() {
        if let cid = route.clusterID {
            PatternLearningEngine.shared.reclassifyCluster(id: cid, markSafe: true)
        }
        var updated = route
        updated.classification = .safe
        updated.userMarkedSafe = true
        RouteStore.shared.updateRoute(updated)
        NotificationCenter.default.post(name: .routeDataUpdated, object: nil)
        dismiss()
    }

    private func deleteRoute() {
        RouteStore.shared.deleteRoute(id: route.id)
        NotificationCenter.default.post(name: .routeDataUpdated, object: nil)
        dismiss()
    }
}
