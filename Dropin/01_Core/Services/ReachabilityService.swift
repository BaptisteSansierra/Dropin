//
//  ReachabilityService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/1/26.
//

import Network
import SwiftUI

@MainActor
protocol ReachabilityListener: AnyObject {
    func reachabilityDidChange(isConnected: Bool)
}

@MainActor
protocol ReachabilityServiceProtocol {
    var isConnected: Bool { get }

    func addListener(_ listener: ReachabilityListener)
    func removeListener(_ listener: ReachabilityListener)
}

// TODO: this shouldn't be MainActor, a background layer may depend of reachability without MainActor dependency

@MainActor
@Observable final class ReachabilityService: Sendable {

    /// Weak so a listener that never calls removeListener (e.g. deallocated without unregistering) doesn't leak
    private struct WeakListener {
        weak var value: ReachabilityListener?
    }

    private(set) var isConnected: Bool = true
    private let verbose: Bool = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "ReachabilityMonitor")
    @ObservationIgnored private var listeners: [WeakListener] = []

    init() {
        Log.debug("🔵 ReachabilityService init", condition: verbose)

        monitor.pathUpdateHandler = { [weak self] path in
            Log.debug("🟢 Path update received on thread: \(Thread.current)", condition: self?.verbose ?? false)
            Log.debug("   Status: \(path.status)", condition: self?.verbose ?? false)
            Log.debug("   Available interfaces: \(path.availableInterfaces)", condition: self?.verbose ?? false)
            Log.debug("   Uses interface type - cellular: \(path.usesInterfaceType(.cellular))", condition: self?.verbose ?? false)
            Log.debug("   Uses interface type - wifi: \(path.usesInterfaceType(.wifi))", condition: self?.verbose ?? false)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let newValue = path.status == .satisfied
                Log.debug("🟡 Updating on main thread", condition: self.verbose)
                guard newValue != self.isConnected else { return }
                self.isConnected = newValue
                Log.debug("🟣 Updated isConnected to: \(self.isConnected)", condition: self.verbose)
                self.notifyListeners(isConnected: newValue)
            }
        }
        Log.debug("🔵 Starting monitor", condition: verbose)
        monitor.start(queue: queue)

        // Also get initial state
        DispatchQueue.main.async {
            self.isConnected = self.monitor.currentPath.status == .satisfied
        }
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - private
    private func notifyListeners(isConnected: Bool) {
        listeners.removeAll { $0.value == nil }
        listeners.forEach { $0.value?.reachabilityDidChange(isConnected: isConnected) }
    }
}

extension ReachabilityService: ReachabilityServiceProtocol {
    func addListener(_ listener: ReachabilityListener) {
        listeners.append(WeakListener(value: listener))
    }

    func removeListener(_ listener: ReachabilityListener) {
        listeners.removeAll { $0.value === listener || $0.value == nil }
    }
}
