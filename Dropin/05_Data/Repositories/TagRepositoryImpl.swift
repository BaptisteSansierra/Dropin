//
//  TagRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import SwiftData

public final class TagRepositoryImpl: TagRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ tag: TagEntity) async throws -> TagEntity {
        throw AppError.notImplemented
    }
    
    func delete(_ tag: TagEntity) async throws {
        throw AppError.notImplemented
    }
    
    func getAll() async throws -> [TagEntity] {
        throw AppError.notImplemented
    }
}
