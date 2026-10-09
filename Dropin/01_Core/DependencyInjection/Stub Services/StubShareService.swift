//
//  StubShareService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op auth and sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import Foundation

final class StubShareService: ShareServiceProtocol {
    func shareURL(placeId: UUID) async throws -> URL {
        URL(string: "https://dropin.lat/p.html?id=\(UUID().uuidString)")!
    }
}

#endif
