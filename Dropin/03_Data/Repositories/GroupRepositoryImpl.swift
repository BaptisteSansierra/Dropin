//
//  GroupRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData

public final class GroupRepositoryImpl: GroupRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: repository protocol methods
    func exists(_ group: GroupEntity) async throws -> Bool {
        do {
            _ = try await retrieveGroup(domainGroup: group)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }

    func create(_ group: GroupEntity) async throws {
        let sdGroup = GroupMapper.toData(group)
        modelContext.insert(sdGroup)
        try modelContext.save()
    }
    
    func delete(_ group: GroupEntity) async throws {
        let model = try await retrieveGroup(domainGroup: group)
        modelContext.delete(model)
        try modelContext.save()
    }
    
    func update(_ group: GroupEntity) async throws {
        let model = try await retrieveGroup(domainGroup: group)
        model.name = group.name
        model.color = group.color
        try modelContext.save()
    }
    
    func fetch() async throws -> [GroupEntity] {
        let desc = FetchDescriptor<SDGroup>(sortBy: [SortDescriptor(\SDGroup.name),
                                                     SortDescriptor(\SDGroup.createdAt)])
        let sdGroups = try modelContext.fetch(desc)
        return sdGroups.map { GroupMapper.toDomain($0) }
    }

    func fetchWithPlaceCount() async throws -> [(GroupEntity, Int)] {
        let desc = FetchDescriptor<SDGroup>(sortBy: [SortDescriptor(\SDGroup.name),
                                                     SortDescriptor(\SDGroup.createdAt)])
        let sdGroups = try modelContext.fetch(desc)
        return sdGroups.map { (GroupMapper.toDomain($0), $0.places.count) }
    }

    func fetch(_ id: UUID) async throws -> GroupEntity {
        let sdGroup = try await retrieveGroup(groupId: id)
        return GroupMapper.toDomain(sdGroup)
    }
    
    // MARK: private methods
    private func retrieveGroup(domainGroup: GroupEntity) async throws -> SDGroup {
        let groupId = domainGroup.id
        return try await retrieveGroup(groupId: groupId)
    }
    
    private func retrieveGroup(groupId: UUID) async throws -> SDGroup {
        let predicate = #Predicate<SDGroup> { $0.identifier == groupId }
        let descriptor = FetchDescriptor<SDGroup>(predicate: predicate)
        let sdGroups = try modelContext.fetch(descriptor)
        guard let result = sdGroups.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(groupId)")
        }
        guard sdGroups.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdGroups.count) SDPlaces with id \(groupId)")
        }
        return result
    }
}
