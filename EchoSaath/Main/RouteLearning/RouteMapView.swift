import SwiftUI
import MapKit

// MARK: - Route Map View
struct RouteMapView: View {
    @EnvironmentObject var tracker: RouteTracker
    @State private var routes: [RouteRecord] = []
    @State private var clusters: [RouteCluster] = []
    @State private var selectedRoute: RouteRecord?
    @State private var showSafeOnly = false
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                // Show current user location
                UserAnnotation()

                // Draw stored routes
                ForEach(filteredRoutes) { route in
                    MapPolyline(coordinates: route.points.map { $0.coordinate })
                        .stroke(colorFor(route.classification), lineWidth: 3)
                }

                // Draw live tracking route
                if tracker.status == .tracking, !tracker.currentRoutePoints.isEmpty {
                    MapPolyline(coordinates: tracker.currentRoutePoints.map { $0.coordinate })
                        .stroke(.red, style: StrokeStyle(lineWidth: 4, dash: [8, 4]))

                    if let last = tracker.currentRoutePoints.last {
                        Annotation("", coordinate: last.coordinate) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onTapGesture { /* consume taps */ }
            
            // Re-center button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            mapPosition = .userLocation(fallback: .automatic)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(10)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                Spacer()
            }

            // Bottom overlay
            VStack(spacing: 0) {
                // Legend + controls
                HStack(spacing: 16) {
                    legendItem(color: .green, label: "Safe")
                    legendItem(color: .blue, label: "Usual")
                    legendItem(color: .orange, label: "New")

                    Spacer()

                    // Filter toggle
                    Button {
                        showSafeOnly.toggle()
                    } label: {
                        Image(systemName: showSafeOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(.pink)
                    }

                    // Status indicator
                    if tracker.status == .tracking {
                        HStack(spacing: 4) {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text("LIVE").font(.caption2.bold()).foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.red.opacity(0.15)))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Route list
                if !filteredRoutes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filteredRoutes.prefix(10)) { route in
                                routeChip(route)
                                    .onTapGesture {
                                        selectedRoute = route
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .sheet(item: $selectedRoute) { route in
            RouteDetailSheet(route: route)
        }
        .onAppear { loadData() }
        .onReceive(NotificationCenter.default.publisher(for: .routeDataUpdated)) { _ in
            loadData()
        }
    }

    // MARK: - Data

    private var filteredRoutes: [RouteRecord] {
        if showSafeOnly {
            return routes.filter { $0.classification == .safe }
        }
        return routes
    }

    private func loadData() {
        routes = RouteStore.shared.loadRoutes()
        clusters = RouteStore.shared.loadClusters()
    }

    // MARK: - Helpers

    private func colorFor(_ classification: RouteClassification) -> Color {
        switch classification {
        case .safe: return .green
        case .usual: return .blue
        case .unusual: return .orange
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 3)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    private func routeChip(_ route: RouteRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: route.classification.icon)
                    .font(.caption2)
                    .foregroundColor(colorFor(route.classification))
                Text(route.classification.rawValue)
                    .font(.caption2.bold())
                    .foregroundColor(colorFor(route.classification))
            }
            Text(route.startTime.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(String(format: "%.0fm", route.distanceMeters))
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
}
