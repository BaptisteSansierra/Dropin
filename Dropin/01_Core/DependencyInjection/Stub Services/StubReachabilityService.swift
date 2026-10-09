//
//  StubReachabilityService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op auth and sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import SwiftUI

@MainActor
@Observable final class StubReachabilityService: ReachabilityServiceProtocol {
    var isConnected: Bool = true
}

#endif
