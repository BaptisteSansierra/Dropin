//
//  StubProfileService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op auth and sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import SwiftUI

@MainActor
@Observable
final class StubProfileService: ProfileServiceProtocol {
    var profile: Profile? = nil
    func load() async {
        profile = Profile(id: UUID(),
                                email: "john.doe@gmail.com",
                                displayName: "John Doe",
                                plan: .earlyStage,
                                createdAt: .now,
                                updatedAt: .now)
    }
    func setDisplayName(_ newValue: String?) async throws {
        guard let profile = profile else {
            assertionFailure("no profile")
            return
        }
        self.profile = Profile(id: UUID(),
                                     email: profile.email,
                                     displayName: newValue,
                                     plan: profile.plan,
                                     createdAt: profile.createdAt,
                                     updatedAt: .now)
    }
    
    func clear() { profile = nil }
}

#endif
