//
//  App_ImportMapstr.swift
//  DropinTests
//
//  Created by baptiste sansierra on 14/9/26.
//

import Foundation
import CoreLocation
import Testing
@testable import Dropin

private class BundleFinder {}

@MainActor
struct App_ImportMapstr {

    private let madeleineName = "Foyer de la Madeleine"
    private let judyName = "Judy Rousseau"
    /// Default data test : 2 Places / 5 Tags
    ///     Place "Foyer de la Madeleine"    -    Tags["À essayer", "Restaurant"]
    ///     Place "Judy Rousseau"    -    Tags["À essayer", "Cafe", "Grignotage", "Tranquilou"]
    private let dataStr = """
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  2.324822,
                  48.86985199999999
                ]
              },
              "properties": {
                "name": "Foyer de la Madeleine",
                "address": "Place de la Madeleine, 75008 Paris, France",
                "icon": "restaurant",
                "tags": [
                  {
                    "name": "À essayer",
                    "color": "#6edf38"
                  },
                  {
                    "name": "Restaurant",
                    "color": "#ff5161"
                  }
                ]
              }
            },
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  2.3405099,
                  48.862383
                ]
              },
              "properties": {
                "name": "Judy Rousseau",
                "address": "14 Rue Jean-Jacques Rousseau, Paris 75001",
                "icon": "cafe",
                "tags": [
                  {
                    "name": "À essayer",
                    "color": "#6edf38"
                  },
                  {
                    "name": "Cafe",
                    "color": "#33d3ff"
                  },
                  {
                    "name": "Grignotage",
                    "color": "#33ff85"
                  },
                  {
                    "name": "Tranquilou",
                    "color": "#ff33c9"
                  }
                ]
              }
            },
          ]
        }
        """
    private var emptyDataStr =
    """
        {
          "type": "FeatureCollection",
          "features": []
        }
    """

    private let localGeneralRepo: MockGeneralRepository = MockGeneralRepository()
    private let localPlaceRepo: MockPlaceRepository = MockPlaceRepository()
    private let localCategoryRepo: MockCategoryRepository = MockCategoryRepository()
    private let localTagRepo: MockTagRepository = MockTagRepository()

    private func importService() -> ImportMapstrService {
        ImportMapstrService(saveContext: SaveContext(repository: localGeneralRepo),
                            rollbackContext: RollbackContext(repository: localGeneralRepo),
                            fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                            fetchCategories: FetchCategories(repository: localCategoryRepo),
                            fetchTags: FetchTags(repository: localTagRepo),
                            upsertPlace: UpsertPlace(repository: localPlaceRepo),
                            upsertCategory: UpsertCategory(repository: localCategoryRepo),
                            upsertTag: UpsertTag(repository: localTagRepo))
    }

    ///
    /// Test ImportMapstrService simple import, no mapping (no tags converted to categories):
    /// places get their tags, no category.
    ///
    @Test func importMapstrServiceBase() async throws {
        let importMapstrService = importService()

        // Phase 1: parse only, writes nothing
        let plan = try await importMapstrService.read(Data(dataStr.utf8))
        #expect(plan.places.count == 2)
        #expect(plan.tags.count == 5)

        // Phase 2: write with an empty mapping
        var counter = 0
        try await importMapstrService.import(plan, mapping: []) { count in
            #expect(count == counter + 1)    // Check progress counter
            counter += 1
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // No tag was converted, so no category is created
            #expect(createdTagsCount == 5)      // Check created tags counter
        }

        let categories = try await localCategoryRepo.fetch()
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // No marker category anymore — an empty mapping creates no category at all
        #expect(categories.count == 0)
        // Check we have 5 tag on disk
        #expect(tags.count == 5)
        // Check we have 2 places on disk
        #expect(places.count == 2)
        guard let madeleine = places.first(where: { $0.name == madeleineName }) else {
            Issue.record("madeleine not found")
            return
        }
        guard let judy = places.first(where: { $0.name == judyName }) else {
            Issue.record("judy not found")
            return
        }
        // Check madeleine has 2 tags
        #expect(madeleine.tags.count == 2)
        // Check judy has 4 tags
        #expect(judy.tags.count == 4)

        // No tag was converted, so no place gets a category
        #expect(madeleine.category == nil)
        #expect(judy.category == nil)
        
        // Check import source
        let importedAt = places[0].importedAt
        let importSrc = places[0].importSrc
        #expect(importedAt != nil)
        #expect(importedAt == tags[0].importedAt)
        //#expect(importedAt == categories[0].importedAt)
        #expect(importSrc == ImportSource.mapstr)
        #expect(importSrc == tags[0].importSrc)
       // #expect(importSrc == categories[0].importSrc)
    }

    ///
    /// Test ImportMapstrService empty file
    ///  check error when file is empty, at phase 1 (read)
    ///
    @Test func importMapstrServiceEmpty() async throws {
        await #expect(throws: ImportError.emptyFile) {
            let importMapstrService = importService()
            _ = try await importMapstrService.read(Data(emptyDataStr.utf8))
        }
    }

    ///
    /// Test ImportMapstrService corrupted file
    ///  check error when file is corrupted, at phase 1 (read)
    ///
    @Test func importMapstrServiceCorrupted() async throws {
        await #expect(throws: ImportError.corrupted("no_matter")) {
            let importMapstrService = importService()
            _ = try await importMapstrService.read(Data("cOrRuptEd".utf8))
        }
    }

    ///
    /// Test ImportMapstrService do not duplicate tags
    ///
    @Test func importMapstrServiceTagsDuplicates() async throws {
        // Fill the local database
        let t1Local = Dropin.Tag(name: "Cafe", color: String.randomColor())
        let t2Local = Dropin.Tag(name: "Grignotage", color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        try await UpsertTag(repository: localTagRepo)(t2Local)

        let importMapstrService = importService()
        let plan = try await importMapstrService.read(Data(dataStr.utf8))
        #expect(plan.places.count == 2)    // Check found places count counter

        try await importMapstrService.import(plan, mapping: []) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 3)      // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check we have 5 tag on disk
        #expect(tags.count == 5)
        guard let madeleine = places.first(where: { $0.name == madeleineName }) else {
            Issue.record("madeleine not found")
            return
        }
        guard let judy = places.first(where: { $0.name == judyName }) else {
            Issue.record("judy not found")
            return
        }
        // Check madeleine has 2 tags
        #expect(madeleine.tags.count == 2)
        // Check judy has 4 tags
        #expect(judy.tags.count == 4)

        // The matched/reused existing tags must be untouched: still no import provenance
        guard let reusedCafe = tags.first(where: { $0.id == t1Local.id }),
              let reusedGrignotage = tags.first(where: { $0.id == t2Local.id }) else {
            Issue.record("reused tags not found")
            return
        }
        #expect(reusedCafe.importedAt == nil)
        #expect(reusedCafe.importSrc == nil)
        #expect(reusedGrignotage.importedAt == nil)
        #expect(reusedGrignotage.importSrc == nil)
    }

    ///
    /// Test ImportMapstrService duplicates soft deleted tags
    ///
    @Test func importMapstrServiceTagsDuplicatesDeleted() async throws {
        // Fill the local database
        var t1Local = Dropin.Tag(name: "Cafe", color: String.randomColor())
        t1Local = t1Local.deleted(deletedAt: Date())
        var t2Local = Dropin.Tag(name: "Grignotage", color: String.randomColor())
        t2Local = t2Local.deleted(deletedAt: Date())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        try await UpsertTag(repository: localTagRepo)(t2Local)

        let importMapstrService = importService()
        let plan = try await importMapstrService.read(Data(dataStr.utf8))
        #expect(plan.places.count == 2)    // Check found places count counter

        try await importMapstrService.import(plan, mapping: []) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check we have 7 tag on disk
        #expect(tags.count == 7)
        // Check we have 2 soft deleted tags on disk
        #expect(tags.reduce(0) { $1.deletedAt == nil ? $0 : $0 + 1 } == 2)
        guard let madeleine = places.first(where: { $0.name == madeleineName }) else {
            Issue.record("madeleine not found")
            return
        }
        guard let judy = places.first(where: { $0.name == judyName }) else {
            Issue.record("judy not found")
            return
        }
        // Check madeleine has 2 tags
        #expect(madeleine.tags.count == 2)
        // Check judy has 4 tags
        #expect(judy.tags.count == 4)
        // Check madeleine is not linked to soft deleted tags
        #expect(madeleine.tags.reduce(0) { $1.deletedAt == nil ? $0 : $0 + 1 } == 0)
        // Check judy is not linked to soft deleted tags
        #expect(judy.tags.reduce(0) { $1.deletedAt == nil ? $0 : $0 + 1 } == 0)
    }

    ///
    /// Test ImportMapstrService do not duplicate places
    ///     madeleine should be detected as a duplicate
    ///     judy should not be detected as a duplicate as coordinates are different
    ///
    @Test func importMapstrServicePlacesDuplicates() async throws {
        // Fill the local database
        let madeleineCoords = CLLocationCoordinate2D(latitude: 48.86985199999999, longitude: 2.324822)
        let madeleineLocal = Place(id: UUID(), name: madeleineName, coordinates: madeleineCoords, address: "nop")
        try await UpsertPlace(repository: localPlaceRepo)(madeleineLocal)
        let judyLocal = Place(id: UUID(), name: judyName, coordinates: .abbeyRoad, address: "nop")
        try await UpsertPlace(repository: localPlaceRepo)(judyLocal)

        let importMapstrService = importService()
        let plan = try await importMapstrService.read(Data(dataStr.utf8))
        #expect(plan.places.count == 2)    // Check found places count counter

        try await importMapstrService.import(plan, mapping: []) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 1)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        let places = try await localPlaceRepo.fetch()
        // Check we have 3 places on disk
        #expect(places.count == 3)
        // Check there are 2 Judy
        let judies = places.filter({ $0.name == judyName })
        #expect(judies.count == 2)
    }

    ///
    /// Test ImportMapstrService duplicates soft deleted places
    ///
    @Test func importMapstrServicePlacesDuplicatesDeleted() async throws {
        // Fill the local database
        let madeleineCoords = CLLocationCoordinate2D(latitude: 48.86985199999999, longitude: 2.324822)
        var madeleineLocal = Place(id: UUID(), name: madeleineName, coordinates: madeleineCoords, address: "nop")
        madeleineLocal = madeleineLocal.deleted(deletedAt: Date())
        try await UpsertPlace(repository: localPlaceRepo)(madeleineLocal)

        let importMapstrService = importService()
        let plan = try await importMapstrService.read(Data(dataStr.utf8))
        #expect(plan.places.count == 2)    // Check found places count counter

        try await importMapstrService.import(plan, mapping: []) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        let places = try await localPlaceRepo.fetch()
        // Check we have 3 places on disk
        #expect(places.count == 3)
        // Check there are 2 Madeleines
        let madeleines = places.filter({ $0.name == madeleineName })
        #expect(madeleines.count == 2)
    }

    ///
    /// Test ImportMapstrService with a non-empty mapping: a converted tag becomes
    /// the category for places that have it, and is still created as a tag for
    /// places that have ANOTHER converted tag (i.e. lost the priority conflict).
    ///
    @Test func importMapstrServiceWithMapping() async throws {
        let importMapstrService = importService()
        let plan = try await importMapstrService.read(Data(dataStr.utf8))

        // "Restaurant" only tags madeleine — convert it to a category.
        let mapping: CategoryMapping = [
            CategoryConversion(tagID: "Restaurant", target: .new(name: "Restaurant", color: "FF5161", icon: .sf("fork.knife")))
        ]

        try await importMapstrService.import(plan, mapping: mapping) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 2)
            #expect(duplicatePlacesCount == 0)
            #expect(createdCategoriesCount == 1)
            // 5 tags total, minus "Restaurant" (never kept as a tag — it always wins where it appears) = 4
            #expect(createdTagsCount == 4)
        }

        let categories = try await localCategoryRepo.fetch()
        #expect(categories.count == 1)
        #expect(categories.first?.name == "Restaurant")
        // Check import source on the freshly-created category
        #expect(categories.first?.importedAt != nil)
        #expect(categories.first?.importSrc == ImportSource.mapstr)

        let places = try await localPlaceRepo.fetch()
        guard let madeleine = places.first(where: { $0.name == madeleineName }) else {
            Issue.record("madeleine not found")
            return
        }
        guard let judy = places.first(where: { $0.name == judyName }) else {
            Issue.record("judy not found")
            return
        }
        // madeleine had ["À essayer", "Restaurant"] — Restaurant becomes its category, "À essayer" stays a tag
        #expect(madeleine.category?.name == "Restaurant")
        #expect(madeleine.tags.count == 1)
        // judy never had "Restaurant": no category, all 4 tags kept
        #expect(judy.category == nil)
        #expect(judy.tags.count == 4)

        // Category, places and the places' own tags all share the exact same import instant
        #expect(madeleine.importedAt == categories.first?.importedAt)
        #expect(judy.importedAt == categories.first?.importedAt)
        #expect(madeleine.importSrc == ImportSource.mapstr)
        #expect(judy.importSrc == ImportSource.mapstr)
    }
}
