//
//  Dropin_DomainTests.swift
//  DropinTests
//
//  Created by baptiste sansierra on 19/7/25.
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

struct Domain_UseCases {

    @MainActor
    @Test func createPlace() async throws {
        let placeRepo = MockPlaceRepository()
        let createPlaceUC = CreatePlace(repository: placeRepo)

        let place = Place(id: UUID(),
                          name: "London",
                          coordinates: .london,
                          address: "",
                          address2: "",
                          tags: [],
                          icon: .sf("tag"),
                          createdAt: Date())
        // Check first creation is ok
        do {
            try await createPlaceUC(place)
            #expect(true)
        } catch {
            Issue.record("could not create place")
        }
        // Check 2nd creation of same object throws an error
        await #expect(throws: DomainError.Place.alreadyExists, performing: {
            try await createPlaceUC(place)
        })
        
        // Check empty names are not accepted
        let placeWithEmptyName = Place(id: UUID(),
                                         name: "",
                                         coordinates: CLLocationCoordinate2D.zero,
                                         address: "",
                                         address2: "",
                                         tags: [],
                                         icon: .sf("tag"),
                                         createdAt: Date())
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await createPlaceUC(placeWithEmptyName)
        })
    }
    
    @MainActor
    @Test func deletePlace() async throws {
        let placeRepo = MockPlaceRepository()
        let fetchPlacesUC = FetchPlaces(repository: placeRepo)
        let createPlaceUC = CreatePlace(repository: placeRepo)
        //let deletePlaceUC = DeletePlace(repository: placeRepo)

        let place = Place(id: UUID(),
                                name: "London",
                                coordinates: .london,
                                address: "",
                                address2: "",
                                tags: [],
                                icon: .sf("tag"),
                                createdAt: Date())
        
        var placesOrigin = [Place]()
        var placesAfterInsert = [Place]()
        var placesAfterFirstDelete = [Place]()
        do {
            placesOrigin = try await fetchPlacesUC()
            try await createPlaceUC(place)
            placesAfterInsert = try await fetchPlacesUC()
            #expect(true)
        } catch {
            Issue.record("could not create place")
        }
        #expect(placesOrigin.count == 0)
        #expect(placesAfterInsert.count == 1)
        /* Delete was removed temporarily, must be restored for DB cleanup background task
        // Check 1st delete place ok
        do {
            try await deletePlaceUC(place)
            placesAfterFirstDelete = try await fetchPlacesUC()
            #expect(true)
        } catch {
            Issue.record("could not delete place")
        }
        #expect(placesAfterFirstDelete.count == 0)
        // Check 2nd delete place fails
        await #expect(throws: DomainError.Place.notFound, performing: {
            try await deletePlaceUC(place)
        })
         */
    }
    
    @Test func createCategory() async throws {
        let groupRepo = await MockCategoryRepository()
        let createCategoryUC = await CreateCategory(repository: groupRepo)

        // Check invalid icons are not accepted
//        let groupWithoutIco = Category(name: "dummy", color: "#000000", icon: Icon("none:none"))
//        await #expect(throws: DomainError.Category.undefinedMarker, performing: {
//            try await createCategoryUC()groupWithoutIco)
//        })
        
        // Check invalid colors are not accepted
        let groupWithoutColor = Dropin.Category(name: "dummy", color: "#0Z0T", icon: Icon.sf("tag"))
        await #expect(throws: DomainError.Category.invalidColor, performing: {
            try await createCategoryUC(groupWithoutColor)
        })
    }
    
    @Test func createTag() async throws {
        let tagRepo = await MockTagRepository()
        let createTagUC = await CreateTag(repository: tagRepo)

        // Check invalid colors are not accepted
        let tag = Dropin.Tag(name: "dummy", color: "1234")
        await #expect(throws: DomainError.Tag.invalidColor, performing: {
            try await createTagUC(tag)
        })
    }
}
