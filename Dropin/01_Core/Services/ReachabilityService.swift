//
//  ReachabilityService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/1/26.
//

import Network
import SwiftUI

protocol ReachabilityServiceProtocol {
    var isConnected: Bool { get }
}

//@MainActor
@Observable final class ReachabilityService: Sendable {
    private(set) var isConnected: Bool = true
    private let verbose: Bool = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "ReachabilityMonitor")

    init() {
        Log.debug("🔵 ReachabilityService init", condition: verbose)

        monitor.pathUpdateHandler = { [weak self] path in
            Log.debug("🟢 Path update received on thread: \(Thread.current)", condition: self?.verbose ?? false)
            Log.debug("   Status: \(path.status)", condition: self?.verbose ?? false)
            Log.debug("   Available interfaces: \(path.availableInterfaces)", condition: self?.verbose ?? false)
            Log.debug("   Uses interface type - cellular: \(path.usesInterfaceType(.cellular))", condition: self?.verbose ?? false)
            Log.debug("   Uses interface type - wifi: \(path.usesInterfaceType(.wifi))", condition: self?.verbose ?? false)

            //Task { @MainActor in
            DispatchQueue.main.async { [weak self] in
                Log.debug("🟡 Updating on main thread", condition: self?.verbose ?? false)
                self?.isConnected = path.status == .satisfied
                Log.debug("🟣 Updated isConnected to: \(self?.isConnected ?? false)", condition: self?.verbose ?? false)
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
}

extension ReachabilityService: ReachabilityServiceProtocol {}

