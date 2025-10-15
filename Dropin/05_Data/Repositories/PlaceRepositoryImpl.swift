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
        
    func create(_ place: PlaceEntity) async throws {
        let sdPlace = PlaceMapper.toData(place)
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        try await linkGroup(sdPlace: sdPlace, domainPlace: place)
        modelContext.insert(sdPlace)
        try modelContext.save()
    }
    
    func delete(_ place: PlaceEntity) async throws {
        let sdPlace = try await retrievePlace(domainPlace: place)
        modelContext.delete(sdPlace)
        try modelContext.save()
    }
    
    func getAll() async throws -> [PlaceEntity] {
        let descriptor = FetchDescriptor<SDPlace>()
        let sdPlaces = try modelContext.fetch(descriptor)
        return sdPlaces.map { PlaceMapper.toDomain($0) }
    }
    
    func update(_ place: PlaceEntity) async throws {
        let sdPlace = try await retrievePlace(domainPlace: place)
        /*
        let placeId = place.id
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        guard let result = sdPlaces.first else {
            throw AppError.sdNotFound(msg: "couldn't find SDPlace with id \(place.id)")
        }
        guard sdPlaces.count < 2 else {
            throw AppError.sdDuplicate(msg: "found \(sdPlaces.count) SDPlaces with id \(place.id)")
        }
         */
        sdPlace.name = place.name
        sdPlace.latitude = place.coordinates.latitude
        sdPlace.longitude = place.coordinates.longitude
        sdPlace.address = place.address
        sdPlace.systemImage = place.systemImage
        sdPlace.notes = place.notes
        sdPlace.phone = place.phone
        sdPlace.url = place.url
        // Link tags
        try await linkTags(sdPlace: sdPlace, domainPlace: place)
        /*
        if place.tags.count > 0 {
            let tagIdentifiers = place.tags.map { $0.id }
            let tagPredicate = #Predicate<SDTag> { tagIdentifiers.contains($0.identifier) }
            let tagDescriptor = FetchDescriptor<SDTag>(predicate: tagPredicate)
            let sdTags = try modelContext.fetch(tagDescriptor)
            if sdTags.count < tagIdentifiers.count {
                throw AppError.sdNotFound(msg: "some tags from list \(tagIdentifiers) couldn't be found")
            }
            if sdTags.count > tagIdentifiers.count {
                throw AppError.sdDuplicate(msg: "found \(sdTags.count) SDTags when looking for \(tagIdentifiers.count) ids : \(tagIdentifiers)")
            }
            result.tags = sdTags
        } else {
            result.tags = []
        } */
        // Link group
        try await linkGroup(sdPlace: sdPlace, domainPlace: place)
        /*
        if let group = place.group {
            let groupId = group.id
            let groupPredicate = #Predicate<SDGroup> { $0.identifier == groupId }
            let groupDescriptor = FetchDescriptor<SDGroup>(predicate: groupPredicate)
            let sdGroups = try modelContext.fetch(groupDescriptor)
            guard let sdGroup = sdGroups.first else {
                throw AppError.sdNotFound(msg: "couldn't find SDGroup with id \(group.id)")
            }
            guard sdGroups.count < 2 else {
                throw AppError.sdDuplicate(msg: "found \(sdGroups.count) SDGroups with id \(group.id)")
            }
            result.group = sdGroup
        } else {
            result.group = nil
        }
         */
        try modelContext.save()
    }

    private func retrievePlace(domainPlace: PlaceEntity) async throws -> SDPlace {
        let placeId = domainPlace.id
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        guard let result = sdPlaces.first else {
            throw AppError.sdNotFound(msg: "couldn't find SDPlace with id \(domainPlace.id)")
        }
        guard sdPlaces.count < 2 else {
            throw AppError.sdDuplicate(msg: "found \(sdPlaces.count) SDPlaces with id \(domainPlace.id)")
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
            throw AppError.sdNotFound(msg: "some tags from list \(tagIdentifiers) couldn't be found")
        }
        if sdTags.count > tagIdentifiers.count {
            throw AppError.sdDuplicate(msg: "found \(sdTags.count) SDTags when looking for \(tagIdentifiers.count) ids : \(tagIdentifiers)")
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
            throw AppError.sdNotFound(msg: "couldn't find SDGroup with id \(group.id)")
        }
        guard sdGroups.count < 2 else {
            throw AppError.sdDuplicate(msg: "found \(sdGroups.count) SDGroups with id \(group.id)")
        }
        sdPlace.group = sdGroup
    }
}

