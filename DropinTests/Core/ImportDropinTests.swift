//
//  ImportDropinTests.swift
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
struct ImportDropinTests {

    private let localGeneralRepo: MockGeneralRepository = MockGeneralRepository()
    private let localPlaceRepo: MockPlaceRepository = MockPlaceRepository()
    private let localGroupRepo: MockGroupRepository = MockGroupRepository()
    private let localTagRepo: MockTagRepository = MockTagRepository()

    private func importService() -> ImportDropinService {
        ImportDropinService(saveContext: SaveContext(repository: localGeneralRepo),
                            rollbackContext: RollbackContext(repository: localGeneralRepo),
                            fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                            fetchGroups: FetchGroups(repository: localGroupRepo),
                            fetchTags: FetchTags(repository: localTagRepo),
                            upsertPlace: UpsertPlace(repository: localPlaceRepo),
                            upsertGroup: UpsertGroup(repository: localGroupRepo),
                            upsertTag: UpsertTag(repository: localTagRepo))
    }
    
    ///
    /// Test ImportDropinService simple import:
    /// one place with a group + one tag
    ///
    @Test func importDropinServiceBase() async throws {
        let g1 = GroupEntity(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let t1 = TagEntity(name: "tag1", color: String.randomColor())
        let p1 = PlaceEntity(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1],
                             group: g1)
        
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       groups: [g1],
                                       tags: [t1])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 1)    // Check created groups counter
            #expect(createdTagsCount == 1)      // Check created tags counter
        }
        let groups = try await localGroupRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have 1 group on disk
        #expect(groups.count == 1)
        // Check we have 1 tag on disk
        #expect(tags.count == 1)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has a group
        guard let extractedGroup = places[0].group else {
            Issue.record("no group")
            return
        }
        // Check place has 1 tag
        #expect(places[0].tags.count == 1)
        // Check place group uuid matches imported group
        #expect(extractedGroup.id == g1.id)
        // Check place tag uuid matches imported tag
        #expect(places[0].tags[0].id == t1.id)
    }

    ///
    /// Test ImportDropinService does not duplicate tags :
    ///  if a tag is found on disk with same name, it should be used instead of imported tag
    ///
    @Test func importDropinServiceDuplicatedTags() async throws {
        // Fill the local database
        let t1Local = TagEntity(name: "tag1", color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        
        // Create the import
        let t1Import = TagEntity(name: "tag1", color: String.randomColor())
        let p1 = PlaceEntity(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1Import])
        
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       groups: [],
                                       tags: [t1Import])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let groups = try await localGroupRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have no groups on disk
        #expect(groups.count == 0)
        // Check we have 1 tag on disk
        #expect(tags.count == 1)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has 1 tag
        #expect(places[0].tags.count == 1)
        // Check place's tag id
        #expect(places[0].tags[0].id == t1Local.id)
    }

    ///
    /// Test ImportDropinService duplicates soft deleted tags
    ///  if a tag is found on disk with same name, but is soft deleted, the duplicate should be ignored and the import should create the tag
    ///
    @Test func importDropinServiceDuplicatedDeletedTags() async throws {
        // Fill the local database
        var t1Local = TagEntity(name: "tag1", color: String.randomColor())
        let t1Import = TagEntity(name: "tag1", color: String.randomColor())
        t1Local = t1Local.deleted(deletedAt: Date())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        
        // Create the import
        let p1 = PlaceEntity(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             tags: [t1Import])
        
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       groups: [],
                                       tags: [t1Import])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)   // Check created places counter
            #expect(duplicatePlacesCount == 0) // Check duplicated places counter
            #expect(createdGroupsCount == 0)   // Check created groups counter
            #expect(createdTagsCount == 1)     // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        // Check we have 2 tags on disk
        #expect(tags.count == 2)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check the created place is linked to new created group
        #expect(places[0].tags[0].id == t1Import.id)
        // Check the 2 groups deletedAt property
        guard let testT1Local = tags.first(where: { $0.id == t1Local.id }) else {
            Issue.record("t1Local not found")
            return
        }
        guard let testT1Imported = tags.first(where: { $0.id == t1Import.id }) else {
            Issue.record("t1Imported not found")
            return
        }
        #expect(testT1Local.deletedAt != nil)
        #expect(testT1Imported.deletedAt == nil)
    }

    ///
    /// Test ImportDropinService does not duplicate groups
    ///  if a group is found on disk with same name, it should be used instead of imported group
    ///
    @Test func importDropinServiceDuplicatedGroups() async throws {
        // Fill the local database
        let g1Local = GroupEntity(name: "group1", color: String.randomColor(), icon: Icon.mock)
        try await UpsertGroup(repository: localGroupRepo)(g1Local)
        
        // Create the import
        let g1Import = GroupEntity(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let p1 = PlaceEntity(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             group: g1Import)
        
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       groups: [g1Import],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let groups = try await localGroupRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we have 1 group on disk
        #expect(groups.count == 1)
        // Check we have no tags on disk
        #expect(tags.count == 0)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        // Check place has a group
        guard let extractedGroup = places[0].group else {
            Issue.record("no group")
            return
        }
        // Check place's group id
        #expect(extractedGroup.id == g1Local.id)
    }

    ///
    /// Test ImportDropinService duplicates soft deleted groups
    ///  if a group is found on disk with same name, but is soft deleted, the duplicate should be ignored and the import should create the group
    ///
    @Test func importDropinServiceDuplicatedDeletedGroups() async throws {
        // Fill the local database
        var g1Local = GroupEntity(name: "group1", color: String.randomColor(), icon: Icon.mock)
        g1Local = g1Local.deleted(deletedAt: Date())
        try await UpsertGroup(repository: localGroupRepo)(g1Local)
        
        // Create the import
        let g1Import = GroupEntity(name: "group1", color: String.randomColor(), icon: Icon.mock)
        let p1 = PlaceEntity(id: UUID(),
                             name: "place1",
                             coordinates: CLLocationCoordinate2D.barcelona,
                             address: "xxx",
                             group: g1Import)
        
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1],
                                       groups: [g1Import],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 1)    // Check created groups counter
            #expect(createdTagsCount == 0)      // Check created tags counter
        }
        let groups = try await localGroupRepo.fetch()
        let tags = try await localTagRepo.fetch()
        // Check we 2 groups on disk
        #expect(groups.count == 2)
        // Check we have no tags on disk
        #expect(tags.count == 0)
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 place on disk
        #expect(places.count == 1)
        guard let extractedGroup = places[0].group else {
            Issue.record("no group")
            return
        }
        // Check the place is linked to new created group
        #expect(extractedGroup.id == g1Import.id)
        // Check the 2 groups deletedAt property
        guard let testG1Local = groups.first(where: { $0.id == g1Local.id }) else {
            Issue.record("g1Local not found")
            return
        }
        guard let testG1Imported = groups.first(where: { $0.id == g1Import.id }) else {
            Issue.record("g1Imported not found")
            return
        }
        #expect(testG1Local.deletedAt != nil)
        #expect(testG1Imported.deletedAt == nil)
    }
    
    ///
    /// Test ImportDropinService does not duplicate places
    ///  if a place is found on disk with same name AND identical coordinates, the place shouldn't be imported
    ///
    @Test func importDropinServiceDuplicatedPlaces() async throws {
        // Fill the local database
        let p1Local = PlaceEntity(id: UUID(),
                                  name: "place1",
                                  coordinates: CLLocationCoordinate2D.barcelona,
                                  address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)
        
        // Create the import
        let p1Import = PlaceEntity(id: UUID(),
                                   name: "plAcE1",   // Insert a case difference, case should be ignored when comparing names
                                   coordinates: CLLocationCoordinate2D.barcelona.offset(x: 0.000135),  // ~15 meters offset
                                   address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1Import],
                                       groups: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 0)    // Check created places counter
            #expect(duplicatePlacesCount == 1)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
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
        var p1Local = PlaceEntity(id: UUID(),
                                  name: "place1",
                                  coordinates: CLLocationCoordinate2D.barcelona,
                                  address: "xxx")
        p1Local = p1Local.deleted(deletedAt: Date())
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)
        
        // Create the import
        let p1Import = PlaceEntity(id: UUID(),
                                   name: "plAcE1",   // Insert a case difference, case should be ignored when comparing names
                                   coordinates: CLLocationCoordinate2D.barcelona.offset(x: 0.000135),  // ~15 meters offset
                                   address: "xxx")
        try await UpsertPlace(repository: localPlaceRepo)(p1Local)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [p1Import],
                                       groups: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        try await importDropinService.execute(data) { placesCount in
            #expect(placesCount == 1)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
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
        guard let testP1Imported = places.first(where: { $0.id == p1Import.id }) else {
            Issue.record("p1Imported not found")
            return
        }
        #expect(testP1Local.deletedAt != nil)
        #expect(testP1Imported.deletedAt == nil)
        #expect(testP1Local.id == p1Local.id)
        #expect(testP1Imported.id == p1Import.id)
    }
    
    ///
    /// Test ImportDropinService empty file
    ///  check error when dropin file is empty
    ///
    @Test func importDropinServiceEmpty() async throws {
        // Create the import
        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: [],
                                       groups: [],
                                       tags: [])
        let data = try ExportService.encoder.encode(dropinExport)

        let importDropinService = importService()
        
        await #expect(throws: ImportError.emptyFile) {
            try await importDropinService.execute(data) { _ in
                #expect(false)    // This should not be reached
            } progress: { _ in
                #expect(false)    // This should not be reached
            } canceled: {
                #expect(false)    // This should not be reached
            } completion: { _, _, _, _ in
                #expect(false)    // This should not be reached
            }
        }
    }
    
    ///
    /// Test ImportDropinService corrupted
    ///  check error when dropin file is corrupted
    ///
    @Test func importDropinServiceCorrupted() async throws {
        
        let data = "This is a corrupted file".data(using: .utf8)!

        let importDropinService = importService()
        
        await #expect(throws: ImportError.corrupted("")) {
            try await importDropinService.execute(data) { _ in
                #expect(false)    // This should not be reached
            } progress: { _ in
                #expect(false)    // This should not be reached
            } canceled: {
                #expect(false)    // This should not be reached
            } completion: { _, _, _, _ in
                #expect(false)    // This should not be reached
            }
        }
    }

    ///
    /// Test ImportDropinService unsupported version
    ///  check error when dropin version is unknown
    ///
    @Test func importDropinServiceUnsupported() async throws {
        let json = """
        { "version": 5678, "exportedAt": "2026-01-01T00:00:00Z", "groups": [], "tags": [], "places": [] }
        """
        let data = Data(json.utf8)
        let importDropinService = importService()
        await #expect(throws: ImportError.versionTooNew(Int.min)) {
            try await importDropinService.execute(data) { _ in
                #expect(false)    // This should not be reached
            } progress: { _ in
                #expect(false)    // This should not be reached
            } canceled: {
                #expect(false)    // This should not be reached
            } completion: { _, _, _, _ in
                #expect(false)    // This should not be reached
            }
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
        #expect(export.groups.count == 7)
        #expect(export.tags.count == 9)
        #expect(export.places.count == 17)
        
        // Assert relationships are coherent
        let tagIds = Set(export.tags.map({ $0.id }))
        let groupIds = Set(export.groups.map(\.id))
        
        for place in export.places {
            // Every tagId on a place references a known tag
            let placeTagIds = place.tags.map({ $0.id })
            #expect(placeTagIds.allSatisfy { tagIds.contains($0) })
            // Every groupId on a place references a known group
            if let groupId = place.group?.id {
                #expect(groupIds.contains(groupId))
            }
        }
    }
    
}
