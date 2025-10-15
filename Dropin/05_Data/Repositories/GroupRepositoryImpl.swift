//
//  GroupRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData

public final class GroupRepositoryImpl: GroupRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ group: GroupEntity) async throws /*-> GroupEntity*/ {
        let sdGroup = GroupMapper.toData(group)
        modelContext.insert(sdGroup)
        try modelContext.save()
        //return group
    }
    
    func delete(_ group: GroupEntity) async throws {
        throw AppError.notImplemented
    }
    
    func update(_ group: GroupEntity) async throws {
        throw AppError.notImplemented
    }
    
    func getAll() async throws -> [GroupEntity] {
        let desc = FetchDescriptor<SDGroup>(sortBy: [SortDescriptor(\SDGroup.name),
                                                     SortDescriptor(\SDGroup.creationDate)])
        let sdGroups = try modelContext.fetch(desc)
        return sdGroups.map { GroupMapper.toDomain($0) }
    }
}
