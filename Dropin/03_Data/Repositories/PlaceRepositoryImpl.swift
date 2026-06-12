//
//  PlaceRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import SwiftData

public final class PlaceRepositoryImpl: PlaceRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: repository protocol methods
    func exists(_ place: PlaceEntity) async throws -> Bool {
        do {
            _ = try await retrievePlace(domainPlace: place)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }
    
    func create(_ place: PlaceEntity) async throws {
        let sdPlace = PlaceMapper.toData(place)
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        try await linkGroup(sdPlace: sdPlace, domainPlace: place)
        modelContext.insert(sdPlace)
        try modelContext.save()
    }
    
    func delete(_ place: PlaceEntity) async throws {
        let model = try await retrievePlace(domainPlace: place)
        modelContext.delete(model)
        try modelContext.save()
    }

    func fetch(_ id: UUID) async throws -> PlaceEntity {
        let sdPlace = try await retrievePlace(uuid: id)
        return PlaceMapper.toDomain(sdPlace)
    }

    func fetch() async throws -> [PlaceEntity] {
        return try await fetch(nil)
    }

    func fetch(_ filter: PlaceFilter?) async throws -> [PlaceEntity] {
        let predicate: Predicate<SDPlace>? = nil
        // predicate = #Predicate<SDPlace> { $0.deletedAt == nil }
        let sorts: [SortDescriptor<SDPlace>] = [SortDescriptor<SDPlace>(\.createdAt), SortDescriptor<SDPlace>(\.name)]
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate, sortBy: sorts)
        let sdPlaces = try modelContext.fetch(descriptor)
        let domainPlaces = sdPlaces.map { PlaceMapper.toDomain($0) }
        if let filter = filter, filter.isActive {
            return domainPlaces.filter { place in
                filter.matches(place)
            }
        } else {
            return domainPlaces
        }
    }
    
    func fetch(groupId: UUID) async throws -> [PlaceEntity] {
        let predicate = #Predicate<SDPlace> { /*$0.deletedAt == nil &&*/ $0.group?.identifier == groupId }
        let sorts: [SortDescriptor<SDPlace>] = [SortDescriptor<SDPlace>(\.createdAt), SortDescriptor<SDPlace>(\.name)]
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate, sortBy: sorts)
        let sdPlaces = try modelContext.fetch(descriptor)
        let domainPlaces = sdPlaces.map { PlaceMapper.toDomain($0) }
        return domainPlaces
    }
    
    func fetch(tagId: UUID) async throws -> [PlaceEntity] {
        let sorts: [SortDescriptor<SDPlace>] = [SortDescriptor<SDPlace>(\.createdAt), SortDescriptor<SDPlace>(\.name)]
        let descriptor = FetchDescriptor<SDPlace>(
            predicate: #Predicate { place in
                /*place.deletedAt == nil &&*/ place.tags.contains { $0.identifier == tagId }
            }, sortBy: sorts
        )
        let sdPlaces = try modelContext.fetch(descriptor)
        let domainPlaces = sdPlaces.map { PlaceMapper.toDomain($0) }
        return domainPlaces
    }
    
    func update(_ place: PlaceEntity) async throws {
        let sdPlace = try await retrievePlace(domainPlace: place)
        sdPlace.name = place.name
        sdPlace.latitude = place.coordinates.latitude
        sdPlace.longitude = place.coordinates.longitude
        sdPlace.address = place.address
        sdPlace.address2 = place.address2
        sdPlace.icon = place.icon
        sdPlace.rating = place.rating
        sdPlace.phone = place.phone
        sdPlace.email = place.email
        sdPlace.url = place.url
        sdPlace.notes = place.notes
        sdPlace.updatedAt = place.updatedAt
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        try await linkGroup(sdPlace: sdPlace, domainPlace: place)
        sdPlace.deletedAt = place.deletedAt
        try modelContext.save()
    }

    func upsert(_ place: PlaceEntity) async throws {
        let placeId = place.id
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        if let existing = try modelContext.fetch(descriptor).first {
            // Update
            existing.name = place.name
            existing.latitude = place.coordinates.latitude
            existing.longitude = place.coordinates.longitude
            existing.address = place.address
            existing.address2 = place.address2
            existing.icon = place.icon
            existing.rating = place.rating
            existing.phone = place.phone
            existing.email = place.email
            existing.url = place.url
            existing.notes = place.notes
            existing.updatedAt = place.updatedAt
            try await linkTags(sdPlace: existing, domainPlace: place)
            try await linkGroup(sdPlace: existing, domainPlace: place)
            existing.deletedAt = place.deletedAt
        } else {
            // Insert
            let sdPlace = PlaceMapper.toData(place)
            try await linkTags(sdPlace: sdPlace, domainPlace: place)
            try await linkGroup(sdPlace: sdPlace, domainPlace: place)
            modelContext.insert(sdPlace)
        }
        try modelContext.save()
    }

    func clearTable() async throws {
        // Batch delete is more efficient but has a limitation, it can't honor relationship rules, may be fixed at some point ?...
        // try modelContext.delete(model: SDPlace.self)

        let all = try modelContext.fetch(FetchDescriptor<SDPlace>())
        for item in all { modelContext.delete(item) }
        try modelContext.save()
    }

    // MARK: private methods
    private func retrievePlace(domainPlace: PlaceEntity) async throws -> SDPlace {
        return try await retrievePlace(uuid: domainPlace.id)
    }
    
    private func retrievePlace(uuid: UUID) async throws -> SDPlace {
        let predicate = #Predicate<SDPlace> { $0.identifier == uuid }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        guard let result = sdPlaces.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(uuid)")
        }
        guard sdPlaces.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdPlaces.count) SDPlaces with id \(uuid)")
        }
        return result
    }
    
    private func linkTags(sdPlace: SDPlace, domainPlace: PlaceEntity) async throws {
        guard domainPlace.tags.count > 0 else {
            sdPlace.tags = []
            return
        }
        let tagIdentifiers = domainPlace.tags.map { $0.id }
        let tagPredicate = #Predicate<SDTag> { tagIdentifiers.contains($0.identifier) }
        let tagDescriptor = FetchDescriptor<SDTag>(predicate: tagPredicate)
        let sdTags = try modelContext.fetch(tagDescriptor)
        if sdTags.count < tagIdentifiers.count {
            throw DataError.notFound(msg: "some tags from list \(tagIdentifiers) couldn't be found")
        }
        if sdTags.count > tagIdentifiers.count {
            throw DataError.duplicate(msg: "found \(sdTags.count) SDTags when looking for \(tagIdentifiers.count) ids : \(tagIdentifiers)")
        }
        sdPlace.tags = sdTags
    }
    
    private func linkGroup(sdPlace: SDPlace, domainPlace: PlaceEntity) async throws {
        guard let group = domainPlace.group else {
            sdPlace.group = nil
            return
        }
        let groupId = group.id
        let groupPredicate = #Predicate<SDGroup> { $0.identifier == groupId }
        let groupDescriptor = FetchDescriptor<SDGroup>(predicate: groupPredicate)
        let sdGroups = try modelContext.fetch(groupDescriptor)
        guard let sdGroup = sdGroups.first else {
            throw DataError.notFound(msg: "couldn't find SDGroup with id \(group.id)")
        }
        guard sdGroups.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdGroups.count) SDGroups with id \(group.id)")
        }
        sdPlace.group = sdGroup
    }
}

