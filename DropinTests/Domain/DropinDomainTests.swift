//
//  DropinDomainTests.swift
//  DropinTests
//
//  Created by baptiste sansierra on 19/7/25.
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

struct DropinDomainTests {

    @MainActor
    @Test func createPlace() async throws {
        let placeRepo = MockPlaceRepository()
        let createPlaceUC = CreatePlace(repository: placeRepo)

        let place = PlaceEntity(id: UUID(),
                                name: "London",
                                coordinates: .london,
                                address: "",
                                address2: "",
                                tags: [],
                                icon: .sf("tag"),
                                createdAt: Date())
        // Check first creation is ok
        do {
            try await createPlaceUC.execute(place)
            #expect(true)
        } catch {
            Issue.record("could not create place")
        }
        // Check 2nd creation of same object throws an error
        await #expect(throws: DomainError.Place.alreadyExists, performing: {
            try await createPlaceUC.execute(place)
        })
        
        // Check empty names are not accepted
        let placeWithEmptyName = PlaceEntity(id: UUID(),
                                             name: "",
                                             coordinates: CLLocationCoordinate2D.zero,
                                             address: "",
                                             address2: "",
                                             tags: [],
                                             icon: .sf("tag"),
                                             createdAt: Date())
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await createPlaceUC.execute(placeWithEmptyName)
        })
    }
    
    @MainActor
    @Test func deletePlace() async throws {
        let placeRepo = MockPlaceRepository()
        let fetchPlacesUC = FetchPlaces(repository: placeRepo)
        let createPlaceUC = CreatePlace(repository: placeRepo)
        let deletePlaceUC = DeletePlace(repository: placeRepo)

        let place = PlaceEntity(id: UUID(),
                                name: "London",
                                coordinates: .london,
                                address: "",
                                address2: "",
                                tags: [],
                                icon: .sf("tag"),
                                createdAt: Date())
        
        var placesOrigin = [PlaceEntity]()
        var placesAfterInsert = [PlaceEntity]()
        var placesAfterFirstDelete = [PlaceEntity]()
        do {
            placesOrigin = try await fetchPlacesUC.execute()
            try await createPlaceUC.execute(place)
            placesAfterInsert = try await fetchPlacesUC.execute()
            #expect(true)
        } catch {
            Issue.record("could not create place")
        }
        #expect(placesOrigin.count == 0)
        #expect(placesAfterInsert.count == 1)
        // Check 1st delete place ok
        do {
            try await deletePlaceUC.execute(place)
            placesAfterFirstDelete = try await fetchPlacesUC.execute()
            #expect(true)
        } catch {
            Issue.record("could not delete place")
        }
        #expect(placesAfterFirstDelete.count == 0)
        // Check 2nd delete place fails
        await #expect(throws: DomainError.Place.notFound, performing: {
            try await deletePlaceUC.execute(place)
        })
    }
    
    @Test func createGroup() async throws {
        let groupRepo = await MockGroupRepository()
        let createGroupUC = await CreateGroup(repository: groupRepo)

        // Check invalid icons are not accepted
//        let groupWithoutIco = GroupEntity(name: "dummy", color: "#000000", icon: Icon("none:none"))
//        await #expect(throws: DomainError.Group.undefinedMarker, performing: {
//            try await createGroupUC.execute(groupWithoutIco)
//        })
        
        // Check invalid colors are not accepted
        let groupWithoutColor = GroupEntity(name: "dummy", color: "#0Z0T", icon: Icon.sf("tag"))
        await #expect(throws: DomainError.Group.invalidColor, performing: {
            try await createGroupUC.execute(groupWithoutColor)
        })
    }
    
    @Test func createTag() async throws {
        let tagRepo = await MockTagRepository()
        let createTagUC = await CreateTag(repository: tagRepo)

        // Check invalid colors are not accepted
        let tag = TagEntity(name: "dummy", color: "1234")
        await #expect(throws: DomainError.Tag.invalidColor, performing: {
            try await createTagUC.execute(tag)
        })
    }
    
    @MainActor
    @Test func filterPlaces() async throws {
        // Create dataset
        var mockPlaces = PlaceEntity.mockPlaces()
        let mockTags = TagEntity.mockTags()
        let mockGroups = GroupEntity.mockGroups()

        // link some objects
        mockPlaces[0] = PlaceEntity(other: mockPlaces[0],
                                    tags: [mockTags[8], mockTags[10], mockTags[13]],
                                    group: mockGroups[0])

        mockPlaces[1] = PlaceEntity(other: mockPlaces[1],
                                    tags: [mockTags[8], mockTags[9], mockTags[13]],
                                    group: mockGroups[0])

        mockPlaces[2] = PlaceEntity(other: mockPlaces[2],
                                    tags: [mockTags[6], mockTags[7]],
                                    group: mockGroups[4])

        mockPlaces[3] = PlaceEntity(other: mockPlaces[3],
                                    tags: [mockTags[1]],
                                    group: mockGroups[5])

        mockPlaces[4] = PlaceEntity(other: mockPlaces[4],
                                    tags: [],
                                    group: mockGroups[1])

        let placeRepo = MockPlaceRepository(initialPlaces: mockPlaces)
        var fetchResult = [PlaceEntity]()
        
        // Check inactive filtering returns all places
        let f1 = PlaceFilter(groupIDs: [], includeUngrouped: false, tagIDs: [], includeUntagged: false)
        do {
            fetchResult = try await placeRepo.fetch(f1)
            #expect(true)
        } catch {
            Issue.record("could not fetch places")
        }
        #expect(fetchResult.count == mockPlaces.count)

        // Check includeUngrouped filtering
        let f2 = PlaceFilter(groupIDs: [], includeUngrouped: true, tagIDs: [], includeUntagged: false)
        let ungroupedPlaces = mockPlaces.filter { $0.group == nil }
        fetchResult = try! await placeRepo.fetch(f2)
        #expect(fetchResult.count == ungroupedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == ungroupedPlaces.map({ $0.id }).sorted())

        // Check includeUntagged filtering
        let f3 = PlaceFilter(groupIDs: [], includeUngrouped: false, tagIDs: [], includeUntagged: true)
        let untaggedPlaces = mockPlaces.filter { $0.tags.count == 0 }
        fetchResult = try! await placeRepo.fetch(f3)
        #expect(fetchResult.count == untaggedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == untaggedPlaces.map({ $0.id }).sorted())
        
        // Check group filtering
        let f4 = PlaceFilter(groupIDs: [mockGroups[0].id], includeUngrouped: false, tagIDs: [], includeUntagged: false)
        fetchResult = try! await placeRepo.fetch(f4)
        #expect(fetchResult.count == 2)
        let f5 = PlaceFilter(groupIDs: [mockGroups[1].id, mockGroups[4].id, mockGroups[5].id])
        fetchResult = try! await placeRepo.fetch(f5)
        #expect(fetchResult.count == 3)

        // Check tag filtering
        let f6 = PlaceFilter(tagIDs: [mockTags[8].id])
        fetchResult = try! await placeRepo.fetch(f6)
        #expect(fetchResult.count == 2)
        let f7 = PlaceFilter(tagIDs: [mockTags[10].id, mockTags[9].id, mockTags[7].id, mockTags[1].id])
        fetchResult = try! await placeRepo.fetch(f7)
        #expect(fetchResult.count == 4)
    }
}
