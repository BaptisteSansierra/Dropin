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
    func exists(_ tag: Tag) async throws -> Bool {
        do {
            _ = try await retrieveTag(domainTag: tag)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }

    func create(_ tag: Tag) async throws {
        let sdTag = TagMapper.toData(tag)
        modelContext.insert(sdTag)
        try modelContext.save()
    }
    
    /* hard delete not used
    func delete(_ tag: Tag) async throws {
        let model = try await retrieveTag(domainTag: tag)
        modelContext.delete(model)
        try modelContext.save()
    }
     */
    
    func update(_ tag: Tag) async throws {
        let model = try await retrieveTag(domainTag: tag)
        model.name = tag.name
        model.color = tag.color
        model.deletedAt = tag.deletedAt
        model.updatedAt = tag.updatedAt
        try modelContext.save()
    }

    func fetch() async throws -> [Tag] {
        // Fetching do not ignore soft deleted objects (deletedAt) as swift UI may still rely on one of them
        let predicate: Predicate<TagRecord>? = nil
        let desc = FetchDescriptor<TagRecord>(predicate: predicate,
                                          sortBy: [SortDescriptor(\TagRecord.name),
                                                   SortDescriptor(\TagRecord.createdAt)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { TagMapper.toDomain($0) }
    }

    func fetchWithPlaceCount() async throws -> [(Tag, Int)] {
        let predicate: Predicate<TagRecord>? = nil
        let desc = FetchDescriptor<TagRecord>(predicate: predicate,
                                          sortBy: [SortDescriptor(\TagRecord.name),
                                                   SortDescriptor(\TagRecord.createdAt)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { (TagMapper.toDomain($0), $0.places.count) }
    }

    func fetch(_ id: UUID) async throws -> Tag {
        let sdTag = try await retrieveTag(tagId: id)
        return TagMapper.toDomain(sdTag)
    }
    
    func upsert(_ tag: Tag, shouldSave: Bool) async throws {
        let descriptor = FetchDescriptor<TagRecord>(predicate: #Predicate { $0.identifier == tag.id })
        if let existing = try modelContext.fetch(descriptor).first {
            // Update
            existing.name      = tag.name
            existing.color     = tag.color
            existing.updatedAt = tag.updatedAt
            existing.deletedAt = tag.deletedAt
        } else if tag.deletedAt == nil {
            // Insert
            let sdTag = TagMapper.toData(tag)
            modelContext.insert(sdTag)
        } else {
            // Tombstone for a tag we never had locally — nothing to do.
            return
        }
        if shouldSave {
            try modelContext.save()
        }
    }
    
    func clearTable() async throws {
        try modelContext.delete(model: TagRecord.self)
        try modelContext.save()
    }
    
    // MARK: private methods
    private func retrieveTag(domainTag: Tag) async throws -> TagRecord {
        let tagId = domainTag.id
        return try await retrieveTag(tagId: tagId)
    }

    private func retrieveTag(tagId: UUID) async throws -> TagRecord {
        let predicate = #Predicate<TagRecord> { $0.identifier == tagId }
        let descriptor = FetchDescriptor<TagRecord>(predicate: predicate)
        let sdTags = try modelContext.fetch(descriptor)
        guard let result = sdTags.first else {
            throw DataError.notFound(msg: "couldn't find TagRecord with id \(tagId)")
        }
        guard sdTags.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdTags.count) TagRecords with id \(tagId)")
        }
        return result
    }
}
