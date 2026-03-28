import Foundation
import Network

/// Monitors network connectivity and publishes changes.
/// Used to show an offline banner instead of crashing when there is no connection.
@MainActor
final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.brickfeed.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
