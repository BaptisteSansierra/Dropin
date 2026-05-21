//
//  MockReachabilityService.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockReachabilityService: ReachabilityServiceProtocol {
    var isConnected: Bool

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}

enum MockSyncError: Error {
    case intentional
}
