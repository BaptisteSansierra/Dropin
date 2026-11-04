//
//  SpaceRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation
import SwiftData

public final class SpaceRepositoryImpl: SpaceRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: repository protocol methods
    func exists(_ space: Space) async throws -> Bool {
        do {
            _ = try await retrieveSpace(domainSpace: space)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }

    func create(_ space: Space) async throws {
        let sdSpace = SpaceMapper.toData(space)
        modelContext.insert(sdSpace)
        try modelContext.save()
    }

    func update(_ space: Space) async throws {
        let model = try await retrieveSpace(domainSpace: space)
        model.name = space.name
        model.color = space.color
        model.icon = space.icon
        model.deletedAt = space.deletedAt
        model.updatedAt = space.updatedAt
        try modelContext.save()
    }

    func fetch() async throws -> [Space] {
        let predicate: Predicate<SpaceRecord>? = nil
        let desc = FetchDescriptor<SpaceRecord>(predicate: predicate,
                                                sortBy: [SortDescriptor(\SpaceRecord.name),
                                                         SortDescriptor(\SpaceRecord.createdAt)])
        let sdSpaces = try modelContext.fetch(desc)
        return sdSpaces.map { SpaceMapper.toDomain($0) }
    }

    func fetch(_ id: UUID) async throws -> Space {
        let sdSpace = try await retrieveSpace(spaceId: id)
        return SpaceMapper.toDomain(sdSpace)
    }

    func upsert(_ space: Space, shouldSave: Bool) async throws {
        let spaceId = space.id
        let descriptor = FetchDescriptor<SpaceRecord>(predicate: #Predicate { $0.identifier == spaceId })
        if let existing = try modelContext.fetch(descriptor).first {
            // Update
            existing.name      = space.name
            existing.color     = space.color
            existing.icon      = space.icon
            existing.updatedAt = space.updatedAt
            existing.deletedAt = space.deletedAt
        } else if space.deletedAt == nil {
            // Insert
            let sdSpace = SpaceMapper.toData(space)
            modelContext.insert(sdSpace)
        } else {
            // Tombstone for a space we never had locally — nothing to do.
            return
        }
        if shouldSave {
            try modelContext.save()
        }
    }

    func clearTable() async throws {
        try modelContext.delete(model: SpaceRecord.self)
        try modelContext.save()
    }

    // MARK: private methods
    private func retrieveSpace(domainSpace: Space) async throws -> SpaceRecord {
        try await retrieveSpace(spaceId: domainSpace.id)
    }

    private func retrieveSpace(spaceId: UUID) async throws -> SpaceRecord {
        let predicate = #Predicate<SpaceRecord> { $0.identifier == spaceId }
        let descriptor = FetchDescriptor<SpaceRecord>(predicate: predicate)
        let sdSpaces = try modelContext.fetch(descriptor)
        guard let result = sdSpaces.first else {
            throw DataError.notFound(msg: "couldn't find SpaceRecord with id \(spaceId)")
        }
        guard sdSpaces.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdSpaces.count) SpaceRecords with id \(spaceId)")
        }
        return result
    }
}
