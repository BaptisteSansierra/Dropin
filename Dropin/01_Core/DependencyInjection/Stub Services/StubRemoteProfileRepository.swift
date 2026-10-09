//
//  StubRemoteProfileRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op auth and sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import Foundation

final class StubRemoteProfileRepository: RemoteProfileRepository {
    func fetch() async throws -> Profile? { nil }
    func fetch(updatedAfter date: Date) async throws -> Profile? { nil }
    func upsert(_ profile: Profile) async throws {}
}

#endif
