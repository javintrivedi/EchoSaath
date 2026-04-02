import Foundation

// MARK: - Route Store (JSON Persistence)
final class RouteStore {
    static let shared = RouteStore()

    private let routesFile = "echosaath_routes.json"
    private let clustersFile = "echosaath_clusters.json"
    private let maxRoutes = 500

    private var cachedRoutes: [RouteRecord]?
    private var cachedClusters: [RouteCluster]?

    private init() {}

    // MARK: - Routes

    func loadRoutes() -> [RouteRecord] {
        if let cached = cachedRoutes { return cached }
        let routes: [RouteRecord] = load(from: routesFile) ?? []
        cachedRoutes = routes
        return routes
    }

    func saveRoute(_ route: RouteRecord) {
        var routes = loadRoutes()
        routes.append(route)
        if routes.count > maxRoutes {
            routes = Array(routes.suffix(maxRoutes))
        }
        cachedRoutes = routes
        save(routes, to: routesFile)
    }

    func updateRoute(_ route: RouteRecord) {
        var routes = loadRoutes()
        if let idx = routes.firstIndex(where: { $0.id == route.id }) {
            routes[idx] = route
            cachedRoutes = routes
            save(routes, to: routesFile)
        }
    }

    func deleteRoute(id: UUID) {
        var routes = loadRoutes()
        routes.removeAll { $0.id == id }
        cachedRoutes = routes
        save(routes, to: routesFile)
    }

    func route(by id: UUID) -> RouteRecord? {
        loadRoutes().first { $0.id == id }
    }

    // MARK: - Clusters

    func loadClusters() -> [RouteCluster] {
        if let cached = cachedClusters { return cached }
        let clusters: [RouteCluster] = load(from: clustersFile) ?? []
        cachedClusters = clusters
        return clusters
    }

    func saveClusters(_ clusters: [RouteCluster]) {
        cachedClusters = clusters
        save(clusters, to: clustersFile)
    }

    func updateCluster(_ cluster: RouteCluster) {
        var clusters = loadClusters()
        if let idx = clusters.firstIndex(where: { $0.id == cluster.id }) {
            clusters[idx] = cluster
        } else {
            clusters.append(cluster)
        }
        cachedClusters = clusters
        save(clusters, to: clustersFile)
    }

    // MARK: - File I/O

    private func fileURL(for name: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(name)
    }

    private func save<T: Encodable>(_ value: T, to file: String) {
        do {
            let data = try JSONEncoder().encode(value)
            let url = fileURL(for: file)
            try data.write(to: url, options: [.atomic])
            // Set file protection
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
        } catch {
            #if DEBUG
            print("[RouteStore] Save error: \(error)")
            #endif
        }
    }

    private func load<T: Decodable>(from file: String) -> T? {
        let url = fileURL(for: file)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[RouteStore] Load error: \(error)")
            #endif
            return nil
        }
    }
}
