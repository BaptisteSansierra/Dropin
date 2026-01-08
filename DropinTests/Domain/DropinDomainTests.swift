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

    @Test func testFoundations() async throws {
        // Test string extension
        #expect("#111".isValidHexaColor)
        #expect("12F".isValidHexaColor)
        #expect("#1a2b3C".isValidHexaColor)
        #expect("F9e0D8".isValidHexaColor)
        #expect(!"#1a2b3".isValidHexaColor)
        #expect(!"F9e0D82".isValidHexaColor)
        #expect(!"QRTYIO".isValidHexaColor)
        // Test CLLocationCoordinate2D extension
        let p1 = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        let p2 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let p3 = CLLocationCoordinate2D(latitude: 10, longitude: 50)
        #expect( p1.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == true )
        #expect( p2.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == false )
        #expect( p3.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == false )
    }

    @MainActor
    @Test func createPlace() async throws {
        let placeRepo = MockPlaceRepository()
        let createPlaceUC = CreatePlace(repository: placeRepo)

        let place = PlaceEntity(id: UUID().uuidString,
                                name: "London",
                                coordinates: DropinApp.locations.london,
                                address: "",
                                tags: [],
                                icon: .sf("tag"),
                                creationDate: Date())
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
        let placeWithEmptyName = PlaceEntity(id: UUID().uuidString,
                                             name: "",
                                             coordinates: CLLocationCoordinate2D.zero,
                                             address: "",
                                             tags: [],
                                             icon: .sf("tag"),
                                             creationDate: Date())
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await createPlaceUC.execute(placeWithEmptyName)
        })
    }
    
    @MainActor
    @Test func deletePlace() async throws {
        let placeRepo = MockPlaceRepository()
        let getPlacesUC = GetPlaces(repository: placeRepo)
        let createPlaceUC = CreatePlace(repository: placeRepo)
        let deletePlaceUC = DeletePlace(repository: placeRepo)

        let place = PlaceEntity(id: UUID().uuidString,
                                name: "London",
                                coordinates: DropinApp.locations.london,
                                address: "",
                                tags: [],
                                icon: .sf("tag"),
                                creationDate: Date())
        
        var placesOrigin = [PlaceEntity]()
        var placesAfterInsert = [PlaceEntity]()
        var placesAfterFirstDelete = [PlaceEntity]()
        do {
            placesOrigin = try await getPlacesUC.execute()
            try await createPlaceUC.execute(place)
            placesAfterInsert = try await getPlacesUC.execute()
            #expect(true)
        } catch {
            Issue.record("could not create place")
        }
        #expect(placesOrigin.count == 0)
        #expect(placesAfterInsert.count == 1)
        // Check 1st delete place ok
        do {
            try await deletePlaceUC.execute(place)
            placesAfterFirstDelete = try await getPlacesUC.execute()
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
}
