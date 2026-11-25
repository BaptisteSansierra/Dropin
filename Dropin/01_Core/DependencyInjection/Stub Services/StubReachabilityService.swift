//
//  StubReachabilityService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

#if DEBUG

import SwiftUI

@MainActor
@Observable final class StubReachabilityService: ReachabilityServiceProtocol {

    private struct WeakListener {
        weak var value: ReachabilityListener?
    }

    var isConnected: Bool = true {
        didSet {
            guard isConnected != oldValue else { return }
            listeners.removeAll { $0.value == nil }
            listeners.forEach { $0.value?.reachabilityDidChange(isConnected: isConnected) }
        }
    }

    @ObservationIgnored private var listeners: [WeakListener] = []

    func addListener(_ listener: ReachabilityListener) {
        listeners.append(WeakListener(value: listener))
    }

    func removeListener(_ listener: ReachabilityListener) {
        listeners.removeAll { $0.value === listener || $0.value == nil }
    }
}

#endif
