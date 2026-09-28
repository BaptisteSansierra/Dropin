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
    
    @MainActor
    @Test func filterPlaces() async throws {
        // Create dataset
        var mockPlaces = Place.mockPlaces()
        let mockTags = Dropin.Tag.mockTags()
        let mockCategories = Dropin.Category.mockCategories()

        // link some objects
        mockPlaces[0] = Place(other: mockPlaces[0],
                                    tags: [mockTags[8], mockTags[10], mockTags[13]],
                                    category: mockCategories[0])

        mockPlaces[1] = Place(other: mockPlaces[1],
                                    tags: [mockTags[8], mockTags[9], mockTags[13]],
                                    category: mockCategories[0])

        mockPlaces[2] = Place(other: mockPlaces[2],
                                    tags: [mockTags[6], mockTags[7]],
                                    category: mockCategories[4])

        mockPlaces[3] = Place(other: mockPlaces[3],
                                    tags: [mockTags[1]],
                                    category: mockCategories[5])

        mockPlaces[4] = Place(other: mockPlaces[4],
                                    tags: [],
                                    category: mockCategories[1])

        let placeRepo = MockPlaceRepository(initialPlaces: mockPlaces)
        var fetchResult = [Place]()
        
        // Check inactive filtering returns all places
        let f1 = PlaceFilter(categoryIDs: [], includeUncategorized: false, tagIDs: [], includeUntagged: false)
        do {
            fetchResult = try await placeRepo.fetch(f1)
            #expect(true)
        } catch {
            Issue.record("could not fetch places")
        }
        #expect(fetchResult.count == mockPlaces.count)

        // Check includeUncategorized filtering
        let f2 = PlaceFilter(categoryIDs: [], includeUncategorized: true, tagIDs: [], includeUntagged: false)
        let uncategorizedPlaces = mockPlaces.filter { $0.category == nil }
        fetchResult = try! await placeRepo.fetch(f2)
        #expect(fetchResult.count == uncategorizedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == uncategorizedPlaces.map({ $0.id }).sorted())

        // Check includeUntagged filtering
        let f3 = PlaceFilter(categoryIDs: [], includeUncategorized: false, tagIDs: [], includeUntagged: true)
        let untaggedPlaces = mockPlaces.filter { $0.tags.count == 0 }
        fetchResult = try! await placeRepo.fetch(f3)
        #expect(fetchResult.count == untaggedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == untaggedPlaces.map({ $0.id }).sorted())
        
        // Check category filtering
        let f4 = PlaceFilter(categoryIDs: [mockCategories[0].id], includeUncategorized: false, tagIDs: [], includeUntagged: false)
        fetchResult = try! await placeRepo.fetch(f4)
        #expect(fetchResult.count == 2)
        let f5 = PlaceFilter(categoryIDs: [mockCategories[1].id, mockCategories[4].id, mockCategories[5].id])
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
