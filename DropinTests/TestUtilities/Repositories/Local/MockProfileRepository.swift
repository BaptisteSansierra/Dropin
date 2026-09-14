//
//  MockProfileRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

@MainActor
final class MockProfileRepository: ProfileRepository {
    private var stored: ProfileEntity?

    init(initial: ProfileEntity? = nil) {
        self.stored = initial
    }

    func fetch() async throws -> ProfileEntity? { stored }

    func upsert(_ profile: ProfileEntity) async throws { stored = profile }

    func update(displayName: String?) async throws -> ProfileEntity {
        guard let current = stored else { throw DataError.notFound(msg: "no profile") }
        let updated = current.withDisplayName(displayName)
        stored = updated
        return updated
    }
    
    func clearTable() async throws {
        stored = nil
    }
}
