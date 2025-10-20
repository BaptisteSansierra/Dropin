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
    
    func getAll() async throws -> [PlaceEntity] {
        let descriptor = FetchDescriptor<SDPlace>()
        let sdPlaces = try modelContext.fetch(descriptor)
        return sdPlaces.map { PlaceMapper.toDomain($0) }
    }
    
    func update(_ place: PlaceEntity) async throws {
        let sdPlace = try await retrievePlace(domainPlace: place)
        sdPlace.name = place.name
        sdPlace.latitude = place.coordinates.latitude
        sdPlace.longitude = place.coordinates.longitude
        sdPlace.address = place.address
        sdPlace.systemImage = place.systemImage
        sdPlace.notes = place.notes
        sdPlace.phone = place.phone
        sdPlace.url = place.url
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        try await linkGroup(sdPlace: sdPlace, domainPlace: place)
        try modelContext.save()
    }

    // MARK: private methods
    private func retrievePlace(domainPlace: PlaceEntity) async throws -> SDPlace {
        let placeId = domainPlace.id
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        guard let result = sdPlaces.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(domainPlace.id)")
        }
        guard sdPlaces.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdPlaces.count) SDPlaces with id \(domainPlace.id)")
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

