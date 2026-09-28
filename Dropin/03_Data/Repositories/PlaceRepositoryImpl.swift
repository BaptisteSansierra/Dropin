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
    func exists(_ place: Place) async throws -> Bool {
        do {
            _ = try await retrievePlace(domainPlace: place)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }
    
    func create(_ place: Place) async throws {
        let sdPlace = PlaceMapper.toData(place)
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        try await linkCategory(sdPlace: sdPlace, domainPlace: place)
        modelContext.insert(sdPlace)
        try modelContext.save()
    }
    
    /* hard delete not used
    func delete(_ place: Place) async throws {
        let model = try await retrievePlace(domainPlace: place)
        modelContext.delete(model)
        try modelContext.save()
    }
     */

    func fetch(_ id: UUID) async throws -> Place {
        let sdPlace = try await retrievePlace(uuid: id)
        return PlaceMapper.toDomain(sdPlace)
    }

    func fetch() async throws -> [Place] {
        return try await fetch(nil)
    }

    func fetch(_ filter: PlaceFilter?) async throws -> [Place] {
        // Fetching do not ignore soft deleted objects (deletedAt) as swift UI may still rely on one of them
        let predicate: Predicate<PlaceRecord>? = nil
        let sorts: [SortDescriptor<PlaceRecord>] = [SortDescriptor<PlaceRecord>(\.createdAt), SortDescriptor<PlaceRecord>(\.name)]
        let descriptor = FetchDescriptor<PlaceRecord>(predicate: predicate, sortBy: sorts)
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
    
    func fetch(categoryId: UUID) async throws -> [Place] {
        let predicate = #Predicate<PlaceRecord> { /*$0.deletedAt == nil &&*/ $0.category?.identifier == categoryId }
        let sorts: [SortDescriptor<PlaceRecord>] = [SortDescriptor<PlaceRecord>(\.createdAt), SortDescriptor<PlaceRecord>(\.name)]
        let descriptor = FetchDescriptor<PlaceRecord>(predicate: predicate, sortBy: sorts)
        let sdPlaces = try modelContext.fetch(descriptor)
        let domainPlaces = sdPlaces.map { PlaceMapper.toDomain($0) }
        return domainPlaces
    }
    
    func fetch(tagId: UUID) async throws -> [Place] {
        let sorts: [SortDescriptor<PlaceRecord>] = [SortDescriptor<PlaceRecord>(\.createdAt), SortDescriptor<PlaceRecord>(\.name)]
        let descriptor = FetchDescriptor<PlaceRecord>(
            predicate: #Predicate { place in
                /*place.deletedAt == nil &&*/ place.tags.contains { $0.identifier == tagId }
            }, sortBy: sorts
        )
        let sdPlaces = try modelContext.fetch(descriptor)
        let domainPlaces = sdPlaces.map { PlaceMapper.toDomain($0) }
        return domainPlaces
    }
    
    func update(_ place: Place) async throws {
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
        try await linkCategory(sdPlace: sdPlace, domainPlace: place)
        sdPlace.deletedAt = place.deletedAt
        try modelContext.save()
    }

    func upsert(_ place: Place, shouldSave: Bool) async throws {
        let placeId = place.id
        let predicate = #Predicate<PlaceRecord> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<PlaceRecord>(predicate: predicate)
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
            try await linkCategory(sdPlace: existing, domainPlace: place)
            existing.deletedAt = place.deletedAt
        } else if place.deletedAt == nil {
            // Insert
            let sdPlace = PlaceMapper.toData(place)
            try await linkTags(sdPlace: sdPlace, domainPlace: place)
            try await linkCategory(sdPlace: sdPlace, domainPlace: place)
            modelContext.insert(sdPlace)
        } else {
            // Tombstone for a place we never had locally — nothing to do.
            return
        }
        if shouldSave {
            try modelContext.save()
        }
    }

    func clearTable() async throws {
        // Batch delete is more efficient but has a limitation, it can't honor relationship rules, may be fixed at some point ?...
        // try modelContext.delete(model: PlaceRecord.self)

        let all = try modelContext.fetch(FetchDescriptor<PlaceRecord>())
        for item in all { modelContext.delete(item) }
        try modelContext.save()
    }

    // MARK: private methods
    private func retrievePlace(domainPlace: Place) async throws -> PlaceRecord {
        return try await retrievePlace(uuid: domainPlace.id)
    }
    
    private func retrievePlace(uuid: UUID) async throws -> PlaceRecord {
        let predicate = #Predicate<PlaceRecord> { $0.identifier == uuid }
        let descriptor = FetchDescriptor<PlaceRecord>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        guard let result = sdPlaces.first else {
            throw DataError.notFound(msg: "couldn't find PlaceRecord with id \(uuid)")
        }
        guard sdPlaces.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdPlaces.count) SDPlaces with id \(uuid)")
        }
        return result
    }
    
    private func linkTags(sdPlace: PlaceRecord, domainPlace: Place) async throws {
        guard domainPlace.tags.count > 0 else {
            sdPlace.tags = []
            return
        }
        let tagIdentifiers = Set(domainPlace.tags.map { $0.id }) // Ensure no duplicates
        let tagPredicate = #Predicate<TagRecord> { tagIdentifiers.contains($0.identifier) }
        let tagDescriptor = FetchDescriptor<TagRecord>(predicate: tagPredicate)
        let sdTags = try modelContext.fetch(tagDescriptor)

        // A referenced tag that isn't found locally means it's been deleted —
        // TagRepositoryImpl.upsert intentionally skips materializing a tombstone
        // for a tag we never had locally. Drop the dangling reference rather
        // than failing the whole place over it.
        if sdTags.count < tagIdentifiers.count {
            Log.debug("linkTags: place \(sdPlace.name) references \(tagIdentifiers.count - sdTags.count) tag(s) no longer available locally — dropping")
        }
        if sdTags.count > tagIdentifiers.count {
            throw DataError.duplicate(msg: "found \(sdTags.count) TagRecords when looking for \(tagIdentifiers.count) ids : \(tagIdentifiers)")
        }
        sdPlace.tags = sdTags
    }
    
    private func linkCategory(sdPlace: PlaceRecord, domainPlace: Place) async throws {
        guard let category = domainPlace.category else {
            sdPlace.category = nil
            return
        }
        let categoryId = category.id
        let categoryPredicate = #Predicate<CategoryRecord> { $0.identifier == categoryId }
        let categoryDescriptor = FetchDescriptor<CategoryRecord>(predicate: categoryPredicate)
        let sdCategories = try modelContext.fetch(categoryDescriptor)
        guard let sdCategory = sdCategories.first else {
            // Same as linkTags: a referenced category that no longer exists
            // locally (deleted, tombstone skipped) shouldn't fail the whole
            // place — just drop the dangling reference.
            Log.debug("linkCategory: place \(sdPlace.name) references category \(category.id) no longer available locally — dropping")
            sdPlace.category = nil
            return
        }
        guard sdCategories.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdCategories.count) CategoryRecords with id \(category.id)")
        }
        sdPlace.category = sdCategory
    }
}

