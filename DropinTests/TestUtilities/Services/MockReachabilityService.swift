//
//  MockReachabilityService.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockReachabilityService: ReachabilityServiceProtocol {
    var isConnected: Bool {
        didSet {
            guard isConnected != oldValue else { return }
            listeners.removeAll { $0.value == nil }
            listeners.forEach { $0.value?.reachabilityDidChange(isConnected: isConnected) }
        }
    }

    private struct WeakListener {
        weak var value: ReachabilityListener?
    }
    private var listeners: [WeakListener] = []

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }

    func addListener(_ listener: ReachabilityListener) {
        listeners.append(WeakListener(value: listener))
    }

    func removeListener(_ listener: ReachabilityListener) {
        listeners.removeAll { $0.value === listener || $0.value == nil }
    }
}

enum MockSyncError: Error {
    case intentional
}
