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

    @Test func createPlace() async throws {
        let placeRepo = await MockPlaceRepository()
        let createPlaceUC = await CreatePlace(repository: placeRepo)
        
        let place = PlaceEntity(id: UUID().uuidString,
                                name: "London",
                                coordinates: DropinApp.locations.london,
                                address: "",
                                systemImage: "tag",
                                tags: [],
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
                                             systemImage: "tag",
                                             tags: [],
                                             creationDate: Date())
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await createPlaceUC.execute(placeWithEmptyName)
        })

        // Check empty sys image are not accepted
        let placeWithEmptySysI = PlaceEntity(id: UUID().uuidString,
                                             name: "world center",
                                             coordinates: CLLocationCoordinate2D.zero,
                                             address: "",
                                             systemImage: "",
                                             tags: [],
                                             creationDate: Date())
        await #expect(throws: DomainError.Place.missingSysImage, performing: {
            try await createPlaceUC.execute(placeWithEmptySysI)
        })
    }
    
    @Test func deletePlace() async throws {
        let placeRepo = await MockPlaceRepository()
        let getPlacesUC = await GetPlaces(repository: placeRepo)
        let createPlaceUC = await CreatePlace(repository: placeRepo)
        let deletePlaceUC = await DeletePlace(repository: placeRepo)

        let place = PlaceEntity(id: UUID().uuidString,
                                name: "London",
                                coordinates: DropinApp.locations.london,
                                address: "",
                                systemImage: "tag",
                                tags: [],
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
}
