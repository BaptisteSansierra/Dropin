//
//  MockSpaceRepository.swift
//  DropinTests
//

import Foundation
@testable import Dropin

@MainActor
final class MockSpaceRepository: SpaceRepository {

    private var spaces: [Space]

    init(initialSpaces: [Space] = []) {
        self.spaces = initialSpaces
    }

    func exists(_ space: Space) async throws -> Bool {
        if let _ = spaces.first(where: { $0.id == space.id }) {
            return true
        }
        return false
    }

    func create(_ space: Space) async throws {
        spaces.append(space)
    }

    func update(_ space: Space) async throws {
        guard let index = spaces.firstIndex(where: { $0.id == space.id }) else {
            throw DataError.notFound(msg: "not found")
        }
        spaces[index] = space
    }

    func fetch() async throws -> [Space] {
        return spaces
    }

    func fetch(_ id: UUID) async throws -> Space {
        guard let s = spaces.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return s
    }

    func upsert(_ space: Space, shouldSave: Bool) async throws {
        if let index = spaces.firstIndex(where: { $0.id == space.id }) {
            spaces[index] = space
        } else {
            spaces.append(space)
        }
    }

    func clearTable() async throws {
        spaces.removeAll()
    }
}
