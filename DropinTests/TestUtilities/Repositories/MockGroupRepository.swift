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
    //private var allPlaces: [PlaceEntity]

//    init(initialGroups: [GroupEntity] = [], allPlaces: [PlaceEntity]) {
//        self.groups = initialGroups
//        self.allPlaces = allPlaces
//    }
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
    
    /*
    func delete(_ group: GroupEntity) async throws {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        Log.info("Remove group at index \(index)")
        groups.remove(at: index)
    }
     */
    
    func update(_ group: GroupEntity) async throws {
    }
    
    func fetch() async throws -> [GroupEntity] {
        return groups
    }
    
    func fetchWithPlaceCount() async throws -> [(Dropin.GroupEntity, Int)] {
        return groups
            .map({ ($0, 0) }) // dummy impl
    }

    func fetch(_ id: UUID) async throws -> GroupEntity {
        guard let g = groups.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return g
    }
    
    func upsert(_ group: GroupEntity, shouldSave: Bool) async throws {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
    }
    
    func clearTable() async throws {
        groups.removeAll()
    }
}
