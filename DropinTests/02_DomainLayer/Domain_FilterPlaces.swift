//
//  Domain_FilterPlaces.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/26.
//

import Testing
import Foundation
@testable import Dropin

struct Domain_FilterPlaces {
    
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
