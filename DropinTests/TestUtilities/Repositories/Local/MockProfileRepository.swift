//
//  MockProfileRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

@MainActor
final class MockProfileRepository: ProfileRepository {
    private var stored: Profile?

    init(initial: Profile? = nil) {
        self.stored = initial
    }

    func fetch() async throws -> Profile? { stored }

    func upsert(_ profile: Profile) async throws { stored = profile }

    func update(displayName: String?) async throws -> Profile {
        guard let current = stored else { throw DataError.notFound(msg: "no profile") }
        let updated = current.withDisplayName(displayName)
        stored = updated
        return updated
    }
    
    func clearTable() async throws {
        stored = nil
    }
}
