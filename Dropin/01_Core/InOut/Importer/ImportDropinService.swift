//
//  ImportDropinService.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation
import CoreLocation

actor ImportDropinService: ImportServiceProtocol {
    
    private let saveContext: SaveContext
    private let rollbackContext: RollbackContext
    private let fetchPlaces: FetchPlaces
    private let fetchGroups: FetchGroups
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertGroup: UpsertGroup
    private let upsertTag: UpsertTag
    
    private var existingHardPlaces: [PlaceEntity] = []  // contains all the non-deleted existing places on disk
    private var existingGroups: [GroupEntity] = []      // contains all the existsing groups on disk
    private var existingTags: [TagEntity] = []          // contains all the existsing tags on disk
    private var createdPlacesCount: Int = 0
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
        try await execute(data,
                          onPlacesCountResolved: onPlacesCountResolved,
                          progress: progress,
                          canceled: canceled,
                          completion: completion)
    }
    
    func execute(_ data: Data,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {

        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        existingGroups = try await fetchGroups()
        existingTags = try await fetchTags()

        guard !Task.isCancelled else { await cancel(canceled); return }
        
        // Decode data
        var export: DropinInOut
        do {
            export = try decode(data)
        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.corrupted(error.localizedDescription)
        }
        Log.info("Found \(export.places.count) places, \(export.tags.count) tags, \(export.groups.count) groups")
        guard export.places.count + export.tags.count + export.groups.count > 0 else {
            throw ImportError.emptyFile
        }
        
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
        await completion(createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount)
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
        
        var replacedTags = [TagEntity: TagEntity]()
        var replacedGroups = [GroupEntity: GroupEntity]()

        // Upsert groups and tags first (places depend on them)
        for group in export.groups {
            try Task.checkCancellation()
            if let existingGroup = existingGroups.first(where: { item in item.name == group.name }),
               existingGroup.isActive {
                replacedGroups[group] = existingGroup
            } else {
                try await upsertGroup(group, shouldSave: false)
                createdGroupsCount += 1
            }
        }
        for tag in export.tags {
            try Task.checkCancellation()
            if let existingTag = existingTags.first(where: { item in item.name == tag.name }),
               existingTag.isActive {
                replacedTags[tag] = existingTag
            } else {
                try await upsertTag(tag, shouldSave: false)
                createdTagsCount += 1
            }
        }
        
        // Replace group and tags in places
        var updatedPlaces: [PlaceEntity] = []
        for place in export.places {
            // Find group replacement if needed
            var group: GroupEntity? = place.group
            if let currentGroup = place.group {
                if let replacement = replacedGroups[currentGroup] {
                    group = replacement
                }
            }
            // Find tags replacements if needed
            var tags: [TagEntity] = []
            for tag in place.tags {
                if let replacement = replacedTags[tag] {
                    tags.append(replacement)
                } else {
                    tags.append(tag)
                }
            }
            // Create place from replaced group and tags
            updatedPlaces.append(place.replacedGroupAndTags(group: group, tags: tags))
        }

        // Upsert places
        var upsertCount = 0
        for place in updatedPlaces {
            try Task.checkCancellation()

            try await processPlace(place)

            upsertCount += 1
            await progress(upsertCount)
        }
    }
    
    private func processPlace(_ place: PlaceEntity) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: place.name, coordinates: place.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }
        
        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(place)
        
        // Add to database
        try await upsertPlace(place, shouldSave: false)
        createdPlacesCount += 1
    }
    
    private func firstPlaceDuplicate(name: String, coordinates: CLLocationCoordinate2D) -> PlaceEntity? {
        for place in existingHardPlaces {
            if place.isIdentical(name: name, coords: coordinates) && place.isActive {
                Log.warning("duplicate found: \(name) > \(place.name) id:\(place.id)")
                return place
            }
        }
        return nil
    }
    
    private func cancel(_ canceled: @MainActor @Sendable () -> Void) async {
        Log.info("DROPIN import canceled")
        await rollbackContext()
        await canceled()
    }
}
