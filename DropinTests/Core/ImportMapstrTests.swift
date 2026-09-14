//
//  ImportMapstrTests.swift
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
struct ImportMapstrTests {
    
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
    
    private let markerName = "MAPSTR_GRP"
    
    private let localGeneralRepo: MockGeneralRepository = MockGeneralRepository()
    private let localPlaceRepo: MockPlaceRepository = MockPlaceRepository()
    private let localGroupRepo: MockGroupRepository = MockGroupRepository()
    private let localTagRepo: MockTagRepository = MockTagRepository()
    
    private func importService() -> ImportMapstrService {
        ImportMapstrService(saveContext: SaveContext(repository: localGeneralRepo),
                            rollbackContext: RollbackContext(repository: localGeneralRepo),
                            fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                            fetchGroups: FetchGroups(repository: localGroupRepo),
                            fetchTags: FetchTags(repository: localTagRepo),
                            upsertPlace: UpsertPlace(repository: localPlaceRepo),
                            upsertGroup: UpsertGroup(repository: localGroupRepo),
                            upsertTag: UpsertTag(repository: localTagRepo),
                            markerGroupName: markerName)
    }
    
    ///
    /// Test ImportMapstrService simple import:
    /// one place with a group + one tag
    ///
    @Test func importMapstrServiceBase() async throws {
        var counter = 0
        let importMapstrService = importService()
        try await importMapstrService.execute(Data(dataStr.utf8)) { placesCount in
            #expect(placesCount == 2)    // Check found places count counter
        } progress: { count in
            #expect(count == counter + 1)    // Check progress counter
            counter += 1
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        
        let groups = try await localGroupRepo.fetch()
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check we have 1 group on disk
        #expect(groups.count == 1)
        // Check we group name is the expected
        #expect(groups[0].name == markerName)
        // Check we have 5 tag on disk
        #expect(tags.count == 5)
        // Check we have 1 place on disk
        #expect(places.count == 2)
        // Check place has a group
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
        
        // Check madeleine has 1 group
        #expect(madeleine.group != nil)
        // Check judy has 1 group
        #expect(judy.group != nil)
    }
    
    ///
    /// Test ImportMapstrService empty file
    ///  check error when file is empty
    ///
    @Test func importMapstrServiceEmpty() async throws {
        await #expect(throws: ImportError.emptyFile) {
            let importMapstrService = importService()
            try await importMapstrService.execute(Data(emptyDataStr.utf8)) { _ in
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
    /// Test ImportMapstrService corrupted file
    ///  check error when file is corrupted
    ///
    @Test func importMapstrServiceCorrupted() async throws {
        await #expect(throws: ImportError.corrupted("no_matter")) {
            let importMapstrService = importService()
            try await importMapstrService.execute(Data("cOrRuptEd".utf8)) { _ in
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
    /// Test ImportMapstrService shouls throw if marker group already exists
    ///
    @Test func importMapstrServiceMarkerError() async throws {
        // Fill the local database
        let g1Local = GroupEntity(name: markerName, color: String.randomColor(), icon: Icon.mock)
        try await UpsertGroup(repository: localGroupRepo)(g1Local)
        // Import
        await #expect(throws: ImportError.markerExists("no_matter")) {
            let importMapstrService = importService()
            try await importMapstrService.execute(Data(dataStr.utf8)) { count in
                #expect(count == 2)
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
    /// Test ImportMapstrService do not duplicate tags
    ///
    @Test func importMapstrServiceTagsDuplicates() async throws {
        // Fill the local database
        let t1Local = TagEntity(name: "Cafe", color: String.randomColor())
        let t2Local = TagEntity(name: "Grignotage", color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        try await UpsertTag(repository: localTagRepo)(t2Local)
        
        let importMapstrService = importService()
        try await importMapstrService.execute(Data(dataStr.utf8)) { placesCount in
            #expect(placesCount == 2)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 3)      // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check we have 5 tag on disk
        #expect(tags.count == 5)
        // Check place has a group
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
    }
    
    ///
    /// Test ImportMapstrService duplicates soft deleted tags
    ///
    @Test func importMapstrServiceTagsDuplicatesDeleted() async throws {
        // Fill the local database
        var t1Local = TagEntity(name: "Cafe", color: String.randomColor())
        t1Local = t1Local.deleted(deletedAt: Date())
        var t2Local = TagEntity(name: "Grignotage", color: String.randomColor())
        t2Local = t2Local.deleted(deletedAt: Date())
        try await UpsertTag(repository: localTagRepo)(t1Local)
        try await UpsertTag(repository: localTagRepo)(t2Local)
        
        let importMapstrService = importService()
        try await importMapstrService.execute(Data(dataStr.utf8)) { placesCount in
            #expect(placesCount == 2)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        let tags = try await localTagRepo.fetch()
        let places = try await localPlaceRepo.fetch()
        // Check we have 7 tag on disk
        #expect(tags.count == 7)
        // Check we have 2 soft deleted tags on disk
        #expect(tags.reduce(0) { $1.deletedAt == nil ? $0 : $0 + 1 } == 2)
        // Check place has a group
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
        let madeleineLocal = PlaceEntity(id: UUID(), name: madeleineName, coordinates: madeleineCoords, address: "nop")
        try await UpsertPlace(repository: localPlaceRepo)(madeleineLocal)
        let judyLocal = PlaceEntity(id: UUID(), name: judyName, coordinates: .abbeyRoad, address: "nop")
        try await UpsertPlace(repository: localPlaceRepo)(judyLocal)
        
        let importMapstrService = importService()
        try await importMapstrService.execute(Data(dataStr.utf8)) { placesCount in
            #expect(placesCount == 2)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 1)    // Check created places counter
            #expect(duplicatePlacesCount == 1)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
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
        var madeleineLocal = PlaceEntity(id: UUID(), name: madeleineName, coordinates: madeleineCoords, address: "nop")
        madeleineLocal = madeleineLocal.deleted(deletedAt: Date())
        try await UpsertPlace(repository: localPlaceRepo)(madeleineLocal)
        
        let importMapstrService = importService()
        try await importMapstrService.execute(Data(dataStr.utf8)) { placesCount in
            #expect(placesCount == 2)    // Check found places count counter
        } progress: { _ in
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdGroupsCount, createdTagsCount in
            #expect(createdPlacesCount == 2)    // Check created places counter
            #expect(duplicatePlacesCount == 0)  // Check duplicated places counter
            #expect(createdGroupsCount == 0)    // Check created groups counter
            #expect(createdTagsCount == 5)      // Check created tags counter
        }
        let places = try await localPlaceRepo.fetch()
        // Check we have 3 places on disk
        #expect(places.count == 3)
        // Check there are 2 Madeleines
        let madeleines = places.filter({ $0.name == madeleineName })
        #expect(madeleines.count == 2)
    }
}
