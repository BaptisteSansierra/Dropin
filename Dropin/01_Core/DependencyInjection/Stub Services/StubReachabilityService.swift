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
    var isConnected: Bool = true
}

#endif
