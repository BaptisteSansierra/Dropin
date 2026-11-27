//
//  App_ImportDropin.swift
//  DropinTests
//
//  Created by baptiste sansierra on 13/9/26.
//

import Foundation
import CoreLocation
import Testing
@testable import Dropin

private class BundleFinder {}

@MainActor
struct App_ImportDropin {

    private let localGeneralRepo: MockGeneralRepository = MockGeneralRepository()
    private let localPlaceRepo: MockPlaceRepository = MockPlaceRepository()
    private let localCategoryRepo: MockCategoryRepository = MockCategoryRepository()
    private let localTagRepo: MockTagRepository = MockTagRepository()

    private func importService() -> ImportDropinService {
        ImportDropinService(saveContext: SaveContext(repository: localGeneralRepo),
                            rollbackContext: RollbackContext(repository: localGeneralRepo),
                            fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                            fetchCategories: FetchCategories(repository: localCategoryRepo),
                            fetchTags: FetchTags(repository: localTagRepo),
                            upsertPlace: UpsertPlace(repository: localPlaceRepo),
                            upsertCategory: UpsertCategory(repository: localCategoryRepo),
                            upsertTag: UpsertTag(repository: localTagRepo))
    }

    ///
    /// Test ImportDropinService simple import:
    /// one place with a category + one tag
    ///
    @Test func importDropinServiceBase() async throws {
        let g1 = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let t1 = Dropin.Tag(name: "tag1", color: String.randomColor())
        let p1 = Place(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1],
                             category: g1)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [g1],
                                       tags: [t1])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 1)// Check created categories counter
            #expect(createdTagsCount == 1)      // Check created tags counter
        }
        let categories = try await localCategoryRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have 1 category on disk
        #expect(categories.count == 1)
        // Check we have 1 tag on disk
        #expect(tags.count == 1)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has a category
        guard let extractedCategory = places[0].category else {
            Issue.record("no category")
            return
        }
        // Check place has 1 tag
        #expect(places[0].tags.count == 1)
        // Check exported ids are never reused: imported entities get a fresh identity
        #expect(places[0].id != p1.id)
        #expect(extractedCategory.id != g1.id)
        #expect(places[0].tags[0].id != t1.id)
        // Check place is linked to the created category / tag
        #expect(extractedCategory.id == categories[0].id)
        #expect(places[0].tags[0].id == tags[0].id)
        
        // Check import source
        let importedAt = places[0].importedAt
        let importSrc = places[0].importSrc
        #expect(importedAt != nil)
        #expect(importedAt == tags[0].importedAt)
        #expect(importedAt == categories[0].importedAt)
        #expect(importSrc == ImportSource.dropin)
        #expect(importSrc == tags[0].importSrc)
        #expect(importSrc == categories[0].importSrc)

        // Check dates are not imported: every date is the import date
        #expect(places[0].createdAt == importedAt)
        #expect(places[0].updatedAt == importedAt)
        #expect(categories[0].createdAt == importedAt)
        #expect(categories[0].updatedAt == importedAt)
        #expect(tags[0].createdAt == importedAt)
        #expect(tags[0].updatedAt == importedAt)
    }

    ///
    /// Test ImportDropinService does not duplicate tags :
    ///  if a tag is found on disk with same name, it should be used instead of imported tag
    ///
    @Test func importDropinServiceDuplicatedTags() async throws {
        // Fill the local database
        let t1Local = Dropin.Tag(name: "tag1", color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(t1Local)

        // Create the import
        let t1Import = Dropin.Tag(name: "tag1", color: String.randomColor())
        let p1 = Place(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1Import])

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [],
                                       tags: [t1Import])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let categories = try await localCategoryRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have no categories on disk
        #expect(categories.count == 0)
        // Check we have 1 tag on disk
        #expect(tags.count == 1)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has 1 tag
        #expect(places[0].tags.count == 1)
        // Check place's tag id
        #expect(places[0].tags[0].id == t1Local.id)
        // The matched/reused existing tag must be untouched, no import provenance
        #expect(tags[0].importedAt == nil)
        #expect(tags[0].importSrc == nil)
    }

    ///
    /// Test ImportDropinService duplicates soft deleted tags
    ///  if a tag is found on disk with same name, but is soft deleted, the duplicate should be ignored and the import should create the tag
    ///
    @Test func importDropinServiceDuplicatedDeletedTags() async throws {
        // Fill the local database
        var t1Local = Dropin.Tag(name: "tag1", color: String.randomColor())
        let t1Import = Dropin.Tag(name: "tag1", color: String.randomColor())
        t1Local = t1Local.deleted(deletedAt: Date())
        try await UpsertTag(repository: localTagRepo)(t1Local)

        // Create the import
        let p1 = Place(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1Import])

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [],
                                       tags: [t1Import])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)   // Check created places counter
            #expect(duplicatePlacesCount == 0) // Check duplicated places counter
            #expect(createdCategoriesCount == 0)   // Check created categories counter
            #expect(createdTagsCount == 1)     // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        // Check we have 2 tags on disk
        #expect(tags.count == 2)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check the 2 tags deletedAt property
        guard let testT1Local = tags.first(where: { $0.id == t1Local.id }) else {
            Issue.record("t1Local not found")
            return
        }
        guard let testT1Imported = tags.first(where: { $0.id != t1Local.id }) else {
            Issue.record("t1Imported not found")
            return
        }
        #expect(testT1Local.deletedAt != nil)
        #expect(testT1Imported.deletedAt == nil)
        // Check the created place is linked to the new created tag, which has a fresh id
        #expect(places[0].tags[0].id == testT1Imported.id)
        #expect(testT1Imported.id != t1Import.id)
    }

    ///
    /// Test ImportDropinService does not duplicate categories
    ///  if a category is found on disk with same name, it should be used instead of imported category
    ///
    @Test func importDropinServiceDuplicatedCategories() async throws {
        // Fill the local database
        let g1Local = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)
        try await UpsertCategory(repository: localCategoryRepo)(g1Local)

        // Create the import
        let g1Import = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let p1 = Place(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             category: g1Import)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [g1Import],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let categories = try await localCategoryRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have 1 category on disk
        #expect(categories.count == 1)
        // Check we have no tags on disk
        #expect(tags.count == 0)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has a category
        guard let extractedCategory = places[0].category else {
            Issue.record("no category")
            return
        }
        // Check place's category id
        #expect(extractedCategory.id == g1Local.id)
        // The matched/reused existing category must be untouched: no import provenance
        #expect(categories[0].importedAt == nil)
        #expect(categories[0].importSrc == nil)
    }

    ///
    /// Test ImportDropinService duplicates soft deleted categories
    ///  if a category is found on disk with same name, but is soft deleted, the duplicate should be ignored and the import should create the category
    ///
    @Test func importDropinServiceDuplicatedDeletedCategories() async throws {
        // Fill the local database
        var g1Local = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)
        g1Local = g1Local.deleted(deletedAt: Date())
        try await UpsertCategory(repository: localCategoryRepo)(g1Local)

        // Create the import
        let g1Import = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let p1 = Place(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             category: g1Import)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [g1Import],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 1)    // Check created categories counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let categories = try await localCategoryRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we 2 categories on disk
        #expect(categories.count == 2)
        // Check we have no tags on disk
        #expect(tags.count == 0)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        guard let extractedCategory = places[0].category else {
            Issue.record("no category")
            return
        }
        // Check the 2 categories deletedAt property
        guard let testG1Local = categories.first(where: { $0.id == g1Local.id }) else {
            Issue.record("g1Local not found")
            return
        }
        guard let testG1Imported = categories.first(where: { $0.id != g1Local.id }) else {
            Issue.record("g1Imported not found")
            return
        }
        #expect(testG1Local.deletedAt != nil)
        #expect(testG1Imported.deletedAt == nil)
        // Check the place is linked to the new created category, which has a fresh id
        #expect(extractedCategory.id == testG1Imported.id)
        #expect(testG1Imported.id != g1Import.id)
    }

    ///
    /// Test ImportDropinService does not duplicate places
    ///  if a place is found on disk with same name AND identical coordinates, the place shouldn't be imported
    ///
    @Test func importDropinServiceDuplicatedPlaces() async throws {
        // Fill the local database
        let p1Local = Place(id: UUID(),
                                  name: "place1",
                                  coordinates: CLLocationCoordinate2D.barcelona,
                                  address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        // Create the import
        let p1Import = Place(id: UUID(),
                                   name: "plAcE1",   // Insert a case difference, case should be ignored when comparing names
                                   coordinates: CLLocationCoordinate2D.barcelona.offset(x: 0.000135),  // ~15 meters offset
                                   address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1Import],
                                       categories: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 0)    // Check created places counter
            #expect(duplicatePlacesCount == 1)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place id
        #expect(places[0].id == p1Local.id)
    }

    ///
    /// Test ImportDropinService  duplicates soft deleted places
    ///  if a place is found on disk with same name AND identical coordinates, the place shouldn't be imported
    ///
    @Test func importDropinServiceDuplicatedDeletedPlaces() async throws {
        // Fill the local database
        var p1Local = Place(id: UUID(),
                                  name: "place1",
                                  coordinates: CLLocationCoordinate2D.barcelona,
                                  address: "xxx")
        p1Local = p1Local.deleted(deletedAt: Date())
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        // Create the import
        let p1Import = Place(id: UUID(),
                                   name: "plAcE1",   // Insert a case difference, case should be ignored when comparing names
                                   coordinates: CLLocationCoordinate2D.barcelona.offset(x: 0.000135),  // ~15 meters offset
                                   address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1Import],
                                       categories: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        let export = try await importDropinService.read(data)
        #expect(export.places.count == 1)    // Check found places count counter

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdCategoriesCount == 0)    // Check created categories counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let places = try await localPlaceRepo.fetch()
        // Check we have 2 place on disk
        #expect(places.count == 2)

        // Check the 2 places deletedAt/id property
        guard let testP1Local = places.first(where: { $0.id == p1Local.id }) else {
            Issue.record("p1Local not found")
            return
        }
        guard let testP1Imported = places.first(where: { $0.id != p1Local.id }) else {
            Issue.record("p1Imported not found")
            return
        }
        #expect(testP1Local.deletedAt != nil)
        #expect(testP1Imported.deletedAt == nil)
        // Check the imported place has a fresh id
        #expect(testP1Imported.id != p1Import.id)
    }

    ///
    /// Test ImportDropinService empty file
    ///  check error when dropin file is empty, at phase 1 (read)
    ///
    @Test func importDropinServiceEmpty() async throws {
        // Create the import
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [],
                                       categories: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()

        await #expect(throws: ImportError.emptyFile) {
            _ = try await importDropinService.read(data)
        }
    }

    ///
    /// Test ImportDropinService file with tags / categories but no place
    ///  check error at phase 1 (read): they're only created for imported places
    ///
    @Test func importDropinServiceNoPlaces() async throws {
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [],
                                       categories: [Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock)],
                                       tags: [Dropin.Tag(name: "tag1", color: String.randomColor())])
        let data = try ExportService.encoder.encode(dropinExport)

        await #expect(throws: ImportError.emptyFile) {
            _ = try await importService().read(data)
        }
    }

    ///
    /// Test ImportDropinService corrupted
    ///  check error when dropin file is corrupted, at phase 1 (read)
    ///
    @Test func importDropinServiceCorrupted() async throws {

        let data = "This is a corrupted file".data(using: .utf8)!

        let importDropinService = importService()

        await #expect(throws: ImportError.decoding("")) {
            _ = try await importDropinService.read(data)
        }
    }

    ///
    /// Test ImportDropinService unsupported version
    ///  check error when dropin version is unknown, at phase 1 (read)
    ///
    @Test func importDropinServiceUnsupported() async throws {
        let json = """
        { "version": 5678, "exportedAt": "2026-01-01T00:00:00Z", "categories": [], "tags": [], "places": [] }
        """
        let data = Data(json.utf8)
        let importDropinService = importService()
        await #expect(throws: ImportError.versionTooNew(Int.min)) {
            _ = try await importDropinService.read(data)
        }
    }

    ///
    /// Test dropin v1 file decoding
    ///
    @Test func decodeDropinFileV1() async throws {

        // Load the file from the test bundle
        let bundle = Bundle(for: BundleFinder.self)
        guard let url = bundle.url(forResource: "exportV1",
                                   withExtension: DropinApp.strings.exportExtension) else {
            Issue.record("exportV1.\(DropinApp.strings.exportExtension) not found in test bundle")
            return
        }

        let data = try Data(contentsOf: url)

        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(DropinInOut.self, from: data)

        // Assert envelope
        #expect(export.version == 1)
        #expect(export.exportedAt < Date())  // Check not distant future

        // Assert counts
        #expect(export.categories.count == 7)
        #expect(export.tags.count == 9)
        #expect(export.places.count == 17)

        // Assert relationships are coherent
        let tagIds = Set(export.tags.map({ $0.id }))
        let categoryIds = Set(export.categories.map(\.id))

        for place in export.places {
            // Every tagId on a place references a known tag
            #expect(place.tagIds.allSatisfy { tagIds.contains($0) })
            // Every categoryId on a place references a known category
            if let categoryId = place.categoryId {
                #expect(categoryIds.contains(categoryId))
            }
        }
    }

    ///
    /// Test exported file never carries place ids nor dates
    ///  tag / category ids are exported, only as file-local references for places
    ///
    @Test func exportOmitsIdsAndDates() async throws {
        // Entities carry import provenance, to check it is not exported either
        let g1 = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock,
                                 importedAt: Date(), importSrc: .mapstr)
        let t1 = Dropin.Tag(name: "tag1", color: String.randomColor(),
                            importedAt: Date(), importSrc: .mapstr)
        let p1 = Place(id: UUID(),
                       name: "place1",
                       coordinates: CLLocationCoordinate2D.barcelona,
                       address: "xxx",
                       tags: [t1],
                       category: g1,
                       importedAt: Date(),
                       importSrc: .mapstr)
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [g1],
                                       tags: [t1])
        let data = try ExportService.encoder.encode(dropinExport)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        let dateKeys = ["createdAt", "updatedAt", "deletedAt", "importedAt", "importSrc"]
        let place = try #require((json["places"] as? [[String: Any]])?.first)
        let tag = try #require((json["tags"] as? [[String: Any]])?.first)
        let category = try #require((json["categories"] as? [[String: Any]])?.first)
        // No place id, no images
        #expect(place["id"] == nil)
        #expect(place["images"] == nil)
        // No dates / provenance
        for key in dateKeys {
            #expect(place[key] == nil)
            #expect(tag[key] == nil)
            #expect(category[key] == nil)
        }
        // Tag / category references are kept
        #expect(tag["id"] as? String == t1.id.uuidString)
        #expect(category["id"] as? String == g1.id.uuidString)
        #expect(place["tagIds"] as? [String] == [t1.id.uuidString])
        #expect(place["categoryId"] as? String == g1.id.uuidString)
    }

    ///
    /// Test ImportDropinService never reuses exported ids, even when they exist locally
    ///  e.g. re-importing one's own export after soft deleting a tag must not resurrect / overwrite the deleted record
    ///
    @Test func importDropinServiceNeverReusesExportedIds() async throws {
        // Fill the local database with a soft deleted tag and category
        let t1Local = Dropin.Tag(name: "tag1", color: String.randomColor()).deleted(deletedAt: Date())
        let g1Local = Dropin.Category(name: "group1", color: String.randomColor(), icon: Icon.mock).deleted(deletedAt: Date())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        try await UpsertCategory(repository: localCategoryRepo)(g1Local)

        // Export carrying the very same ids
        let p1 = Place(id: UUID(),
                       name: "place1",
                       coordinates: CLLocationCoordinate2D.barcelona,
                       address: "xxx",
                       tags: [t1Local.undeleted()],
                       category: g1Local.undeleted())
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       categories: [g1Local.undeleted()],
                                       tags: [t1Local.undeleted()])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        let export = try await importDropinService.read(data)
        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { _, _, createdCategoriesCount, createdTagsCount in
            #expect(createdCategoriesCount == 1)
            #expect(createdTagsCount == 1)
        }

        let tags = try await localTagRepo.fetch()
        let categories = try await localCategoryRepo.fetch()
        // Local records are untouched (still soft deleted), new ones are created alongside
        #expect(tags.count == 2)
        #expect(categories.count == 2)
        #expect(tags.first(where: { $0.id == t1Local.id })?.deletedAt != nil)
        #expect(categories.first(where: { $0.id == g1Local.id })?.deletedAt != nil)
        // The imported place is linked to the new records
        let places = try await localPlaceRepo.fetch()
        #expect(places.count == 1)
        #expect(places[0].tags.map(\.id) != [t1Local.id])
        #expect(places[0].category?.id != g1Local.id)
    }

    /// 2 places: place1 tagged with tag1, place2 without tag
    private func tagImportExport() -> (DropinInOut, Dropin.Tag) {
        let t1 = Dropin.Tag(name: "tag1", color: String.randomColor())
        let p1 = Place(id: UUID(), name: "place1", coordinates: CLLocationCoordinate2D.barcelona, address: "xxx", tags: [t1])
        let p2 = Place(id: UUID(), name: "place2", coordinates: CLLocationCoordinate2D.abbeyRoad, address: "yyy")
        return (DropinInOut(exportedAt: Date(), places: [p1, p2], categories: [], tags: [t1]), t1)
    }

    ///
    /// Test ImportDropinService with tagImport off:
    ///  no import tag is created, even though a tag name is provided
    ///
    @Test func importDropinServiceTagImportOff() async throws {
        let tagName = "Dropin import"
        let (dropinExport, _) = tagImportExport()
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: false, tagName: tagName) { _ in
        } canceled: {
        } completion: { createdPlacesCount, _, _, createdTagsCount in
            #expect(createdPlacesCount == 2)
            #expect(createdTagsCount == 1)      // Only the file's tag
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check no import tag on disk
        #expect(tags.count == 1)
        #expect(!tags.contains { $0.name == tagName })
        // Check no place got the import tag
        #expect(places.count == 2)
        #expect(places.allSatisfy { place in !place.tags.contains { $0.name == tagName } })
    }

    ///
    /// Test ImportDropinService with tagImport on:
    ///  a single import tag is created and added to every imported place, with or without tags of their own
    ///
    @Test func importDropinServiceTagImportOn() async throws {
        let tagName = "Dropin import"
        let (dropinExport, t1) = tagImportExport()
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: true, tagName: tagName) { _ in
        } canceled: {
        } completion: { createdPlacesCount, _, _, createdTagsCount in
            #expect(createdPlacesCount == 2)
            #expect(createdTagsCount == 2)      // The file's tag + the import tag
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check a single import tag on disk
        let importTags = tags.filter { $0.name == tagName }
        #expect(tags.count == 2)
        #expect(importTags.count == 1)
        guard let importTag = importTags.first else { return }
        // Check every imported place got it
        #expect(places.count == 2)
        #expect(places.allSatisfy { place in place.tags.contains { $0.id == importTag.id } })
        // Check place1 kept its own tag next to it
        guard let place1 = places.first(where: { $0.name == "place1" }) else {
            Issue.record("place1 not found")
            return
        }
        #expect(place1.tags.count == 2)
        #expect(place1.tags.contains { $0.name == t1.name })
    }

    ///
    /// Test ImportDropinService with tagImport on, the import tag named like a tag of the file:
    ///  no two tags share the name, every imported place has it once
    ///
    @Test func importDropinServiceTagImportNameInFile() async throws {
        let (dropinExport, t1) = tagImportExport()
        let tagName = t1.name           // place1 already has it in the file, place2 doesn't
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: true, tagName: tagName) { _ in
        } canceled: {
        } completion: { _, _, _, _ in
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check a single tag with that name on disk
        #expect(tags.filter { $0.name.lowercased() == tagName.lowercased() }.count == 1)
        // Check every imported place has it, once
        #expect(places.count == 2)
        for place in places {
            #expect(place.tags.filter { $0.name.lowercased() == tagName.lowercased() }.count == 1, "\(place.name)")
        }
    }

    ///
    /// Test ImportDropinService with tagImport on, the import tag named like an existing local tag:
    ///  the local tag is used, no second tag with that name
    ///
    @Test func importDropinServiceTagImportNameExists() async throws {
        let tagName = "Dropin import"
        let localTag = Dropin.Tag(name: tagName, color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(localTag)

        let (dropinExport, _) = tagImportExport()
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: true, tagName: tagName) { _ in
        } canceled: {
        } completion: { _, _, _, createdTagsCount in
            #expect(createdTagsCount == 1)      // Only the file's tag: the import tag already existed
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check a single tag with that name on disk: the local one
        let namedTags = tags.filter { $0.name.lowercased() == tagName.lowercased() }
        #expect(namedTags.map(\.id) == [localTag.id])
        // Check every imported place has the local tag
        #expect(places.count == 2)
        #expect(places.allSatisfy { place in place.tags.contains { $0.id == localTag.id } })
    }

    ///
    /// Test ImportDropinService with tagImport on, every place being a duplicate:
    ///  nothing is imported, so no import tag is created
    ///
    @Test func importDropinServiceTagImportAllDuplicates() async throws {
        let tagName = "Dropin import"
        let (dropinExport, _) = tagImportExport()
        // Fill the local database with both places (see tagImportExport)
        try await UpsertPlace(repository: localPlaceRepo)(Place(id: UUID(), name: "place1", coordinates: .barcelona, address: "xxx"))
        try await UpsertPlace(repository: localPlaceRepo)(Place(id: UUID(), name: "place2", coordinates: .abbeyRoad, address: "yyy"))
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: true, tagName: tagName) { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, _, _ in
            #expect(createdPlacesCount == 0)
            #expect(duplicatePlacesCount == 2)
        }
        let tags = try await localTagRepo.fetch()
        // Check no import tag on disk
        #expect(!tags.contains { $0.name == tagName })
    }

    ///
    /// Test ImportDropinService creates tags / categories on the fly:
    ///  one only referenced by a duplicate place, or by no place, is never created
    ///
    @Test func importDropinServiceCreatesOnlyUsedTagsAndCategories() async throws {
        // place1 is a duplicate: its category and tag must not be created
        try await UpsertPlace(repository: localPlaceRepo)(Place(id: UUID(), name: "place1", coordinates: .barcelona, address: "xxx"))

        let usedTag = Dropin.Tag(name: "used", color: String.randomColor())
        let duplicateTag = Dropin.Tag(name: "duplicate", color: String.randomColor())
        let unusedTag = Dropin.Tag(name: "unused", color: String.randomColor())
        let duplicateCategory = Dropin.Category(name: "duplicate", color: String.randomColor(), icon: Icon.mock)
        let unusedCategory = Dropin.Category(name: "unused", color: String.randomColor(), icon: Icon.mock)
        let p1 = Place(id: UUID(), name: "place1", coordinates: .barcelona, address: "xxx",
                       tags: [duplicateTag], category: duplicateCategory)
        let p2 = Place(id: UUID(), name: "place2", coordinates: .abbeyRoad, address: "yyy", tags: [usedTag])
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1, p2],
                                       categories: [duplicateCategory, unusedCategory],
                                       tags: [usedTag, duplicateTag, unusedTag])
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 1)
            #expect(duplicatePlacesCount == 1)
            #expect(createdCategoriesCount == 0)
            #expect(createdTagsCount == 1)
        }
        let tags = try await localTagRepo.fetch()
        let categories = try await localCategoryRepo.fetch()
        #expect(tags.map(\.name) == ["used"])
        #expect(categories.isEmpty)
    }

    ///
    /// Test ImportDropinService matches names with `nameKey`:
    ///  case and surrounding whitespaces ignored, within the file and against existing ones
    ///
    @Test func importDropinServiceMatchesNamesStrictly() async throws {
        let localTag = Dropin.Tag(name: "Rooftop", color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(localTag)

        let t1 = Dropin.Tag(name: " rooftop ", color: String.randomColor())     // Same as the local one
        let t2 = Dropin.Tag(name: "Brunch", color: String.randomColor())
        let t3 = Dropin.Tag(name: "brunch  ", color: String.randomColor())     // Same as t2 in the file
        let t4 = Dropin.Tag(name: "Rooftops", color: String.randomColor())     // Not the same: no lemma
        let p1 = Place(id: UUID(), name: "place1", coordinates: .barcelona, address: "xxx", tags: [t1, t2])
        let p2 = Place(id: UUID(), name: "place2", coordinates: .abbeyRoad, address: "yyy", tags: [t3, t4])
        let dropinExport = DropinInOut(exportedAt: Date(), places: [p1, p2], categories: [], tags: [t1, t2, t3, t4])
        let data = try ExportService.encoder.encode(dropinExport)
        let importDropinService = importService()
        let export = try await importDropinService.read(data)

        try await importDropinService.import(export, tagImport: false, tagName: "") { _ in
        } canceled: {
        } completion: { _, _, _, createdTagsCount in
            #expect(createdTagsCount == 2)      // Brunch + Rooftops
        }
        let tags = try await localTagRepo.fetch()
        #expect(Set(tags.map(\.name)) == ["Rooftop", "Brunch", "Rooftops"])
        let places = try await localPlaceRepo.fetch()
        guard let place1 = places.first(where: { $0.name == "place1" }) else {
            Issue.record("place1 not found")
            return
        }
        #expect(place1.tags.contains { $0.id == localTag.id })
    }
}
