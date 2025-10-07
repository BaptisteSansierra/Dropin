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
    
    func create(_ tag: TagEntity) async throws -> TagEntity {
        let sdTag = TagMapper.toData(tag)
        modelContext.insert(sdTag)
        try modelContext.save()
        return tag
    }
    
    func delete(_ tag: TagEntity) async throws {
        throw AppError.notImplemented
    }
    
    func getAll() async throws -> [TagEntity] {
        let desc = FetchDescriptor<SDTag>(sortBy: [SortDescriptor(\SDTag.name),
                                                   SortDescriptor(\SDTag.creationDate)])
        let sdTags = try modelContext.fetch(desc)
        return sdTags.map { TagMapper.toDomain($0) }
    }
}
