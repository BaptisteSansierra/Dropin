//
//  TagRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData

public final class TagRepositoryImpl: TagRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: repository protocol methods
    func exists(_ tag: TagEntity) async throws -> Bool {
        do {
            _ = try await retrieveTag(domainTag: tag)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }

    func create(_ tag: TagEntity) async throws {
        let sdTag = TagMapper.toData(tag)
        modelContext.insert(sdTag)
        try modelContext.save()
    }
    
    func delete(_ tag: TagEntity) async throws {
        let model = try await retrieveTag(domainTag: tag)
        modelContext.delete(model)
        try modelContext.save()
    }
    
    func update(_ tag: TagEntity) async throws {
        let model = try await retrieveTag(domainTag: tag)
        model.name = tag.name
        model.color = tag.color
        try await linkPlaces(sdTag: model, domainTag: tag)
        try modelContext.save()
    }

    func getAll() async throws -> [TagEntity] {
        let desc = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\SDTag.name),
                                                   SortDescriptor(\SDTag.creationDate)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { TagMapper.toDomain($0) }
    }
    
    // MARK: private methods
    private func retrieveTag(domainTag: TagEntity) async throws -> SDTag {
        let tagId = domainTag.id
        let predicate = #Predicate<SDTag> { $0.identifier == tagId }
        let descriptor = FetchDescriptor<SDTag>(predicate: predicate)
        let sdTags = try modelContext.fetch(descriptor)
        guard let result = sdTags.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(domainTag.id)")
        }
        guard sdTags.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdTags.count) SDPlaces with id \(domainTag.id)")
        }
        return result
    }
    
    private func linkPlaces(sdTag: SDTag, domainTag: TagEntity) async throws {
        guard domainTag.places.count > 0 else {
            sdTag.places = []
            return
        }
        let placeIdentifiers = domainTag.places.map { $0.id }
        let predicate = #Predicate<SDPlace> { placeIdentifiers.contains($0.identifier) }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        let sdPlaces = try modelContext.fetch(descriptor)
        if sdPlaces.count < placeIdentifiers.count {
            throw DataError.notFound(msg: "some tags from list \(placeIdentifiers) couldn't be found")
        }
        if sdPlaces.count > placeIdentifiers.count {
            throw DataError.duplicate(msg: "found \(sdPlaces.count) SDTags when looking for \(placeIdentifiers.count) ids : \(placeIdentifiers)")
        }
        sdTag.places = sdPlaces
    }
}
