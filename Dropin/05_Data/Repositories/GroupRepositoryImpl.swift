//
//  GroupRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import SwiftData

public final class GroupRepositoryImpl: GroupRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ group: GroupEntity) async throws -> GroupEntity {
        throw AppError.notImplemented
    }
    
    func delete(_ group: GroupEntity) async throws {
        throw AppError.notImplemented
    }
    
    func getAll() async throws -> [GroupEntity] {
        throw AppError.notImplemented
    }
}
