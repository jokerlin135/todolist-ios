//
//  NetworkMonitor.swift
//  aatodo
//
//  Network monitoring using NWPathMonitor
//  Issue: aatodo-8oz.2
//

import Foundation
import Network

// MARK: - Network Monitor

/// Network monitor singleton for tracking network reachability
/// - Uses NWPathMonitor to detect network status changes
/// - Posts notification when network becomes available
/// - Thread-safe with main thread updates for UI
final class NetworkMonitor: ObservableObject {
    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    /// Current network connection status
    @Published var isConnected: Bool = false

    // MARK: - Private Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton pattern
    }

    // MARK: - Public Methods

    /// Start monitoring network changes
    /// - Must be called to begin monitoring
    /// - Updates isConnected on main thread for UI binding
    /// - Posts notification when network becomes available
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)

                // Post notification when network becomes available after being unavailable
                if path.status == .satisfied {
                    NotificationCenter.default.post(
                        name: .networkDidBecomeAvailable,
                        object: nil
                    )
                }
            }
        }

        monitor.start(queue: queue)
    }

    /// Stop monitoring network changes
    /// - Call when monitoring is no longer needed
    func stop() {
        monitor.cancel()
    }
}
