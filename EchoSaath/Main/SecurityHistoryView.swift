import SwiftUI
import MapKit
import CoreLocation

struct SecurityHistoryView: View {
    @EnvironmentObject var processor: EventProcessor
    @State private var filter: HistoryFilter = .all
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All Events"
        case alerts = "Alerts Only"
    }
    
    private var filteredEvents: [ProcessedEvent] {
        switch filter {
        case .all:
            return processor.recentEvents
        case .alerts:
            return processor.recentEvents.filter { $0.riskLevel == .critical || $0.riskLevel == .elevated }
        }
    }
    
    var body: some View {
        ZStack {
            Color.appBackgroundPink.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tracking Status Banner
                if !SensorManager.shared.isMonitoring {
                    trackingStatusBanner
                }
                
                // Filter Picker
                Picker("Filter", selection: $filter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredEvents.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                SecurityEventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
        }
        .navigationTitle("Security History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    processor.addTestEvent()
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            if !filteredEvents.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        processor.clearAllEvents()
                    } label: {
                        Text("Clear")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
            Text("No history found")
                .font(.headline)
            Text("Events and alerts with their locations will appear here as they are recorded.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var trackingStatusBanner: some View {
        Button {
            SensorManager.shared.startMonitoring()
        } label: {
            HStack {
                Image(systemName: "location.slash.fill")
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location Tracking Paused")
                        .font(.subheadline.bold())
                    Text("Tap to enable 24/7 background protection.")
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
        }
    }
}

struct SecurityEventCard: View {
    let event: ProcessedEvent
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Small Map
            if let lat = event.latitude, let lon = event.longitude {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))) {
                    Marker(event.reason, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tint(riskColor)
                }
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .allowsHitTesting(false) // Let the card's tap gesture handle it
                .padding(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                    VStack(spacing: 4) {
                        Image(systemName: "map.fill")
                        Text("No Location").font(.system(size: 8))
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(width: 110, height: 110)
                .padding(8)
            }
            
            // Right: Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    riskBadge
                    Spacer()
                    Text(event.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                Text(event.reason)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack {
                    Image(systemName: "calendar")
                    Text(event.timestamp.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.trailing, 12)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            if event.latitude != nil {
                openInMaps()
            }
        }
    }
    
    private var riskColor: Color {
        switch event.riskLevel {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        }
    }
    
    private var riskBadge: some View {
        Text(event.riskLevel.rawValue.uppercased())
            .font(.system(size: 8, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(riskColor))
    }
    
    private func openInMaps() {
        guard let lat = event.latitude, let lon = event.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.reason
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue
        ])
    }
}

#Preview {
    NavigationStack {
        SecurityHistoryView()
            .environmentObject(EventProcessor.shared)
    }
}
