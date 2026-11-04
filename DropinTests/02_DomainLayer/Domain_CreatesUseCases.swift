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

    // MARK: - UpsertXInSpace

    @MainActor
    @Test func upsertPlaceInSpaceRejectsEmptyName() async throws {
        let placeRepo = MockPlaceRepository()
        let sut = UpsertPlaceInSpace(repository: placeRepo)
        let place = Place(id: UUID(), name: "", coordinates: .barcelona, address: "")
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await sut(place, spaceId: UUID())
        })
    }

    @MainActor
    @Test func upsertPlaceInSpaceForwardsExplicitSpaceId() async throws {
        let placeRepo = MockPlaceRepository()
        let sut = UpsertPlaceInSpace(repository: placeRepo)
        let spaceId = UUID()
        let place = Place(id: UUID(), name: "La Chitarra", coordinates: .barcelona, address: "")

        try await sut(place, spaceId: spaceId)

        #expect(placeRepo.lastUpsertSpaceId == spaceId)
        let stored = try await placeRepo.fetch(place.id)
        #expect(stored.id == place.id)
    }

    @Test func upsertCategoryInSpaceRejectsEmptyName() async throws {
        let categoryRepo = await MockCategoryRepository()
        let sut = await UpsertCategoryInSpace(repository: categoryRepo)
        let category = Dropin.Category(name: "", color: "9944AA", icon: .sf("tag"))
        await #expect(throws: DomainError.Category.missingName, performing: {
            try await sut(category, spaceId: UUID())
        })
    }

    @Test func upsertCategoryInSpaceForwardsExplicitSpaceId() async throws {
        let categoryRepo = await MockCategoryRepository()
        let sut = await UpsertCategoryInSpace(repository: categoryRepo)
        let spaceId = UUID()
        let category = Dropin.Category(name: "Restaurant", color: "9944AA", icon: .sf("tag"))

        try await sut(category, spaceId: spaceId)

        let lastSpaceId = await categoryRepo.lastUpsertSpaceId
        #expect(lastSpaceId == spaceId)
        let stored = try await categoryRepo.fetch(category.id)
        #expect(stored.id == category.id)
    }

    @Test func upsertTagInSpaceRejectsEmptyName() async throws {
        let tagRepo = await MockTagRepository()
        let sut = await UpsertTagInSpace(repository: tagRepo)
        let tag = Dropin.Tag(name: "", color: "9944AA")
        await #expect(throws: DomainError.Tag.missingName, performing: {
            try await sut(tag, spaceId: UUID())
        })
    }

    @Test func upsertTagInSpaceForwardsExplicitSpaceId() async throws {
        let tagRepo = await MockTagRepository()
        let sut = await UpsertTagInSpace(repository: tagRepo)
        let spaceId = UUID()
        let tag = Dropin.Tag(name: "Clean restrooms", color: "9944AA")

        try await sut(tag, spaceId: spaceId)

        let lastSpaceId = await tagRepo.lastUpsertSpaceId
        #expect(lastSpaceId == spaceId)
        let stored = try await tagRepo.fetch(tag.id)
        #expect(stored.id == tag.id)
    }
}
