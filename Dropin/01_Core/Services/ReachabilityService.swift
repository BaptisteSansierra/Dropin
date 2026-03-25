//
//  ReachabilityService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/1/26.
//

import Network
import SwiftUI

//@MainActor
@Observable final class ReachabilityService: Sendable {
    private(set) var isConnected: Bool = true
    private let verbose: Bool = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "ReachabilityMonitor")

    init() {
        if verbose {
            print("🔵 ReachabilityService init")
        }

        monitor.pathUpdateHandler = { [weak self] path in
            if let self = self, self.verbose {
                print("🟢 Path update received on thread: \(Thread.current)")
                print("   Status: \(path.status)")
                print("   Available interfaces: \(path.availableInterfaces)")
                print("   Uses interface type - cellular: \(path.usesInterfaceType(.cellular))")
                print("   Uses interface type - wifi: \(path.usesInterfaceType(.wifi))")
            }

            //Task { @MainActor in
            DispatchQueue.main.async { [weak self] in
                if let self = self, self.verbose {
                    print("🟡 Updating on main thread")
                }
                self?.isConnected = path.status == .satisfied
                if let self = self, self.verbose {
                    print("🟣 Updated isConnected to: \(self.isConnected)")
                }
            }
        }
        if verbose {
            print("🔵 Starting monitor")
        }
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

