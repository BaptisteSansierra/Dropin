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
        try modelContext.save()
    }

    func fetch() async throws -> [TagEntity] {
        let desc = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\SDTag.name),
                                                   SortDescriptor(\SDTag.createdAt)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { TagMapper.toDomain($0) }
    }

    func fetchWithPlaceCount() async throws -> [(TagEntity, Int)] {
        let desc = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\SDTag.name),
                                                   SortDescriptor(\SDTag.createdAt)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { (TagMapper.toDomain($0), $0.places.count) }
    }

    func fetch(_ id: UUID) async throws -> TagEntity {
        let sdTag = try await retrieveTag(tagId: id)
        return TagMapper.toDomain(sdTag)
    }
    
    func upsert(_ tag: TagEntity) async throws {
        let descriptor = FetchDescriptor<SDTag>(predicate: #Predicate { $0.identifier == tag.id })
        if let existing = try modelContext.fetch(descriptor).first {
            // Update
            existing.name      = tag.name
            existing.color     = tag.color
            existing.deletedAt = tag.deletedAt
        } else {
            // Insert
            let sdTag = TagMapper.toData(tag)
            modelContext.insert(sdTag)
        }
        try modelContext.save()
    }
    
    // MARK: private methods
    private func retrieveTag(domainTag: TagEntity) async throws -> SDTag {
        let tagId = domainTag.id
        return try await retrieveTag(tagId: tagId)
    }

    private func retrieveTag(tagId: UUID) async throws -> SDTag {
        let predicate = #Predicate<SDTag> { $0.identifier == tagId }
        let descriptor = FetchDescriptor<SDTag>(predicate: predicate)
        let sdTags = try modelContext.fetch(descriptor)
        guard let result = sdTags.first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(tagId)")
        }
        guard sdTags.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdTags.count) SDPlaces with id \(tagId)")
        }
        return result
    }
}
