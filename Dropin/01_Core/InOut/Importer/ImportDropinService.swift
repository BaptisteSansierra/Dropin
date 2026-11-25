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
        let export: DropinInOut = try decode(data)
        Log.info("Found \(export.places.count) places, \(export.tags.count) tags, \(export.categories.count) categories")
        // Tags and categories are only created for imported places: no place, nothing to import
        guard export.places.count > 0 else {
            throw ImportError.emptyFile
        }
        return export
    }

    // MARK: - Phase 2: import (writes)
    func `import`(_ export: DropinInOut,
                  tagImport: Bool,
                  tagName: String,
                  progress: @MainActor @Sendable (Int) -> Void,
                  canceled: @MainActor @Sendable () -> Void,
                  completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        existingCategories = try await fetchCategories()
            .filter { $0.isActive }
        existingTags = try await fetchTags()
            .filter { $0.isActive }

        guard !Task.isCancelled else { await cancel(canceled); return }

        // Create items
        do {
            try await createLocalItems(export,
                                       tagImport: tagImport,
                                       tagName: tagName,
                                       progress: progress)
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
        do {
            let export = try decoder.decode(DropinInOut.self, from: data)
            switch export.version {
                case 1:
                    return export
                default:
                    throw ImportError.versionTooNew(export.version)
            }
        } catch {
            var msg = error.localizedDescription
            if let decodingError = error as? DecodingError {
                switch decodingError {
                    case .keyNotFound(let key, let context):
                        msg = "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)"
                    case .typeMismatch(let type, let context):
                        msg = "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                    case .valueNotFound(let type, let context):
                        msg = "Null value for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                    case .dataCorrupted(let context):
                        msg = "Corrupted data at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
                    @unknown default:
                        msg = "\(decodingError)"
                }
            }
            Log.warning("Decoding error: \(msg)")
            throw ImportError.decoding(msg)
        }
    }

    private func createLocalItems(_ export: DropinInOut,
                                  tagImport: Bool,
                                  tagName: String,
                                  progress: @MainActor @Sendable (Int) -> Void) async throws {

        // Every entity created by this import run shares the same instant.
        // The .dropin wire format carries no ids/dates of its own:
        // this importer assigns a fresh identity and stamps every date with importDate.
        let importDate = Date()

        // File-local ids, only referenced by the places
        let categoriesByFileId = Dictionary(export.categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let tagsByFileId = Dictionary(export.tags.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let importTagName = tagImport ? tagName.trimmedName.nonEmpty : nil

        var upsertCount = 0
        for placeDTO in export.places {
            try Task.checkCancellation()
            try await processPlace(placeDTO,
                                   categoriesByFileId: categoriesByFileId,
                                   tagsByFileId: tagsByFileId,
                                   importTagName: importTagName,
                                   importDate: importDate)
            upsertCount += 1
            await progress(upsertCount)
        }
    }

    private func processPlace(_ placeDTO: DropinPlaceDTO,
                              categoriesByFileId: [UUID: DropinCategoryDTO],
                              tagsByFileId: [UUID: DropinTagDTO],
                              importTagName: String?,
                              importDate: Date) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: placeDTO.name, coordinates: placeDTO.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }

        // Category and tags are resolved for created places only: an unused one is never created
        var category: Category?
        if let categoryDTO = placeDTO.categoryId.flatMap({ categoriesByFileId[$0] }) {
            category = try await resolveCategory(categoryDTO.toDomain(importDate: importDate))
        }
        var tags: [Tag] = []
        for tagDTO in placeDTO.tagIds.compactMap({ tagsByFileId[$0] }) {
            let tag = try await resolveTag(tagDTO.toDomain(importDate: importDate))
            if !tags.contains(tag) { tags.append(tag) }
        }
        if let importTagName {
            let tag = try await resolveTag(Tag(name: importTagName, color: String.randomColor(),
                                               importedAt: importDate, importSrc: .dropin))
            if !tags.contains(tag) { tags.append(tag) }
        }

        let place = placeDTO.toDomain(tags: tags, category: category, importDate: importDate)
        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(place)

        // Add to database
        try await upsertPlace(place, shouldSave: false)
        createdPlacesCount += 1
    }

    /// The active category named like `candidate` (`nameKey`), else `candidate` once created
    private func resolveCategory(_ candidate: Category) async throws -> Category {
        if let existing = existingCategories.firstActive(named: candidate.name) { return existing }
        let category = candidate.trimmingName()
        try await upsertCategory(category, shouldSave: false)
        existingCategories.append(category)
        createdCategoriesCount += 1
        return category
    }

    /// The active tag named like `candidate` (`nameKey`), else `candidate` once created
    private func resolveTag(_ candidate: Tag) async throws -> Tag {
        if let existing = existingTags.firstActive(named: candidate.name) { return existing }
        let tag = candidate.trimmingName()
        try await upsertTag(tag, shouldSave: false)
        existingTags.append(tag)
        createdTagsCount += 1
        return tag
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
