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
    private let fetchCategories: FetchCategories
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertCategory: UpsertCategory
    private let upsertTag: UpsertTag

    private var existingHardPlaces: [Place] = []  // contains all the non-deleted existing places on disk
    private var existingCategories: [Category] = []      // contains all the existsing categories on disk
    private var existingTags: [Tag] = []          // contains all the existsing tags on disk
    private var createdPlacesCount: Int = 0
    private var duplicatePlacesCount: Int = 0
    private var createdTagsCount: Int = 0
    private var createdCategoriesCount: Int = 0

    init(saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertCategory: UpsertCategory,
         upsertTag: UpsertTag) {
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertCategory = upsertCategory
        self.upsertTag = upsertTag
    }

    // MARK: - Phase 1: read (parse only, writes nothing)
    func read(_ url: URL) async throws -> DropinInOut {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try await read(data)
    }

    func read(_ data: Data) async throws -> DropinInOut {
        let export: DropinInOut
        do {
            export = try decode(data)
        } catch let error as ImportError {
            throw error
        } catch {
            throw ImportError.corrupted(error.localizedDescription)
        }
        Log.info("Found \(export.places.count) places, \(export.tags.count) tags, \(export.categories.count) categories")
        guard export.places.count + export.tags.count + export.categories.count > 0 else {
            throw ImportError.emptyFile
        }
        return export
    }

    // MARK: - Phase 2: import (writes)
    func `import`(_ export: DropinInOut,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        existingCategories = try await fetchCategories()
        existingTags = try await fetchTags()

        guard !Task.isCancelled else { await cancel(canceled); return }

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
        await completion(createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount)
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

        // Every entity created by this import run shares the same instant.
        // The .dropin wire format carries no import provenance of its own,
        // this importer is the one that supplies it.
        let importDate = Date()

        var replacedTags = [Tag: Tag]()
        var replacedCategories = [Category: Category]()

        // Upsert categories and tags first (places depend on them)
        for category in export.categories {
            try Task.checkCancellation()
            if let existingCategory = existingCategories.first(where: { item in item.name == category.name }),
               existingCategory.isActive {
                replacedCategories[category] = existingCategory
            } else {
                let stampedCategory = category.withImportProvenance(importedAt: importDate, importSrc: .dropin)
                try await upsertCategory(stampedCategory, shouldSave: false)
                createdCategoriesCount += 1
            }
        }
        for tag in export.tags {
            try Task.checkCancellation()
            if let existingTag = existingTags.first(where: { item in item.name == tag.name }),
               existingTag.isActive {
                replacedTags[tag] = existingTag
            } else {
                let stampedTag = tag.withImportProvenance(importedAt: importDate, importSrc: .dropin)
                try await upsertTag(stampedTag, shouldSave: false)
                createdTagsCount += 1
            }
        }

        // Replace category and tags in places
        var updatedPlaces: [Place] = []
        for place in export.places {
            // Find category replacement if needed
            var category: Category? = place.category
            if let currentCategory = place.category {
                if let replacement = replacedCategories[currentCategory] {
                    category = replacement
                }
            }
            // Find tags replacements if needed
            var tags: [Tag] = []
            for tag in place.tags {
                if let replacement = replacedTags[tag] {
                    tags.append(replacement)
                } else {
                    tags.append(tag)
                }
            }
            // Create place from replaced category and tags
            updatedPlaces.append(place.replacedCategoryAndTags(category: category, tags: tags))
        }

        // Upsert places
        var upsertCount = 0
        for place in updatedPlaces {
            try Task.checkCancellation()

            try await processPlace(place, importDate: importDate)

            upsertCount += 1
            await progress(upsertCount)
        }
    }

    private func processPlace(_ place: Place, importDate: Date) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: place.name, coordinates: place.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }

        let stampedPlace = place.withImportProvenance(importedAt: importDate, importSrc: .dropin)

        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(stampedPlace)

        // Add to database
        try await upsertPlace(stampedPlace, shouldSave: false)
        createdPlacesCount += 1
    }

    private func firstPlaceDuplicate(name: String, coordinates: CLLocationCoordinate2D) -> Place? {
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
