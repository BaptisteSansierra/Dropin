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
        try await linkPlaces(sdGroup: model, domainGroup: group)
        try modelContext.save()
    }
    
    func getAll() async throws -> [GroupEntity] {
        let desc = FetchDescriptor<SDGroup>(sortBy: [SortDescriptor(\SDGroup.name),
                                                     SortDescriptor(\SDGroup.creationDate)])
        let sdGroups = try modelContext.fetch(desc)
        return sdGroups.map { GroupMapper.toDomain($0) }
    }
    
    // MARK: private methods
    private func retrieveGroup(domainGroup: GroupEntity) async throws -> SDGroup {
        let groupId = domainGroup.id
        let predicate = #Predicate<SDGroup> { $0.identifier == groupId }
        let descriptor = FetchDescriptor<SDGroup>(predicate: predicate)
        let sdGroups = try modelContext.fetch(descriptor)
        guard let result = sdGroups.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(domainGroup.id)")
        }
        guard sdGroups.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdGroups.count) SDPlaces with id \(domainGroup.id)")
        }
        return result
    }
    
    private func linkPlaces(sdGroup: SDGroup, domainGroup: GroupEntity) async throws {
        guard domainGroup.places.count > 0 else {
            sdGroup.places = []
            return
        }
        let placeIdentifiers = domainGroup.places.map { $0.id }
        let predicate = #Predicate<SDPlace> { placeIdentifiers.contains($0.identifier) }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        if sdPlaces.count < placeIdentifiers.count {
            throw DataError.notFound(msg: "some groups from list \(placeIdentifiers) couldn't be found")
        }
        if sdPlaces.count > placeIdentifiers.count {
            throw DataError.duplicate(msg: "found \(sdPlaces.count) SDGroups when looking for \(placeIdentifiers.count) ids : \(placeIdentifiers)")
        }
        sdGroup.places = sdPlaces
    }
}
