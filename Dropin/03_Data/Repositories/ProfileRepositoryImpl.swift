//
//  ProfileRepositoryImpl.swift
//  Dropin
//

import Foundation
import SwiftData

final class ProfileRepositoryImpl: ProfileRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetch() async throws -> ProfileEntity? {
        // There's only ever one row for the signed-in user (RLS scopes it).
        let desc = FetchDescriptor<SDProfile>()
        return try modelContext.fetch(desc).first.map { ProfileMapper.toDomain($0) }
    }
    
    func upsert(_ profile: ProfileEntity) async throws {
        let targetId = profile.id
        let desc = FetchDescriptor<SDProfile>(predicate: #Predicate { $0.identifier == targetId })
        if let existing = try modelContext.fetch(desc).first {
            existing.email       = profile.email
            existing.displayName = profile.displayName
            existing.plan        = profile.plan.rawValue
            existing.updatedAt   = profile.updatedAt
        } else {
            modelContext.insert(ProfileMapper.toData(profile))
        }
        try modelContext.save()
    }
    
    /// `updatedAt` stamping point for the profile: any intent-specific update
    /// method on this impl (currently just `update(displayName:)`) must set
    /// `sd.updatedAt = Date()` before saving. Profile uses intent-specific APIs
    /// rather than a generic `update(_:entity)`, so the stamp can't live on
    /// the `Syncing*Repository` decorator like it does for places/groups/tags
    /// — it lives here, at the persistence layer. If you add another
    /// `update(field:)` method, remember to stamp here too.
    func update(displayName: String?) async throws -> ProfileEntity {
        let desc = FetchDescriptor<SDProfile>()
        guard let sd = try modelContext.fetch(desc).first else {
            throw DataError.notFound(msg: "no SDProfile to update")
        }
        sd.displayName = displayName
        sd.updatedAt = Date()
        try modelContext.save()
        return ProfileMapper.toDomain(sd)
    }
    
    func clearTable() async throws {
        try modelContext.delete(model: SDProfile.self)
        try modelContext.save()
    }
}
