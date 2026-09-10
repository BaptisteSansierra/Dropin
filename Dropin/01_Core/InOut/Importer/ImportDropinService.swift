//
//  ImportDropinService.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

actor ImportDropinService: ImportServiceProtocol {
    
    private let saveContext: SaveContext
    private let rollbackContext: RollbackContext
    private let fetchPlaces: FetchPlaces
    private let fetchGroups: FetchGroups
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertGroup: UpsertGroup
    private let upsertTag: UpsertTag
    
    private var duplicatePlacesCount: Int = 0
    private var createdTagsCount: Int = 0
    private var createdGroupsCount: Int = 0
    
    init(saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag) {
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertGroup = upsertGroup
        self.upsertTag = upsertTag
    }

    func execute(_ url: URL,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        // Read file
        let data = try Data(contentsOf: url)
        guard !Task.isCancelled else { await cancel(canceled); return }
        
        // Decode data
        let export = try decode(data)
        Log.info("Found \(export.places.count) places, \(export.tags.count) tags, \(export.groups.count) groups")
        guard !Task.isCancelled else { await cancel(canceled); return }
        await onPlacesCountResolved(export.places.count)
        
        // Create items
        do {
            try await createLocalItems(export, progress: progress)
        } catch is CancellationError {
            await cancel(canceled);
        }
        
        // Persist items and complete
        guard !Task.isCancelled else { return }
        try await saveContext()
        Log.info(" -> persisted")
        await completion(export.places.count, duplicatePlacesCount, createdGroupsCount, createdTagsCount)
    }

    // MARK: - Private
    private func decode(_ data: Data) throws -> DropinInOut {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let export = try decoder.decode(DropinInOut.self, from: data)

        switch export.version {
            case 1:
                return export
            default:
                throw ImportError.versionTooNew(export.version)
        }
    }

    private func createLocalItems(_ export: DropinInOut, progress: @MainActor @Sendable (Int) -> Void) async throws {
        // Upsert groups and tags first (places depend on them)
        for group in export.groups {
            try Task.checkCancellation()
            try await upsertGroup(group, shouldSave: false)
        }
        for tag in export.tags {
            try Task.checkCancellation()
            try await upsertTag(tag, shouldSave: false)
        }
        createdGroupsCount = export.groups.count
        createdTagsCount = export.tags.count
        // Upsert places
        var upsertCount = 0
        for place in export.places {
            try Task.checkCancellation()
            try await upsertPlace(place, shouldSave: false)
            upsertCount += 1
            await progress(upsertCount)
        }
    }
    
    private func cancel(_ canceled: @MainActor @Sendable () -> Void) async {
        Log.info("DROPIN import canceled")
        await rollbackContext()
        await canceled()
    }
}
