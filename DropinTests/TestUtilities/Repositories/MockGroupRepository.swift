//
//  MockGroupRepository.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

@MainActor
final class MockGroupRepository: GroupRepository {
    
    private var groups: [GroupEntity]
    
    init(initialGroups: [GroupEntity] = []) {
        self.groups = initialGroups
    }
    
    func exists(_ place: GroupEntity) async throws -> Bool {
        if let _ = groups.first(where: { $0.id == place.id }) {
            return true
        }
        return false
    }
    
    func create(_ group: GroupEntity) async throws {
        groups.append(group)
    }
    
    func delete(_ group: GroupEntity) async throws {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        Log.info("Remove group at index \(index)")
        groups.remove(at: index)
    }
    
    func update(_ group: GroupEntity) async throws {
    }
    
    func fetch() async throws -> [GroupEntity] {
        return groups
    }
    
    func fetch(_ id: UUID) async throws -> GroupEntity {
        guard let g = groups.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return g
    }
}
