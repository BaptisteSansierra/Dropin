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
    func createDataSet() -> ([Place], [Dropin.Tag], [Dropin.Category], MockPlaceRepository) {
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

        mockPlaces[5] = Place(other: mockPlaces[5],
                              tags: [mockTags[8], mockTags[10]],
                              category: mockCategories[5])
        
        return (mockPlaces, mockTags, mockCategories, MockPlaceRepository(initialPlaces: mockPlaces))
    }
    
    @MainActor
    @Test func emptyFilter() async throws {
        let (mockPlaces, _, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()
        
        // Check inactive filtering returns all places
        let filter = PlaceFilter(categoryIDs: [], includeUncategorized: false, tagIDs: [], includeUntagged: false)
        do {
            fetchResult = try await placeRepo.fetch(filter)
            #expect(true)
        } catch {
            Issue.record("could not fetch places")
        }
        #expect(fetchResult.count == mockPlaces.count)
    }
    
    @MainActor
    @Test func includeUncategorized() async throws {
        let (mockPlaces, _, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()
        
        // Check includeUncategorized filtering
        let filter = PlaceFilter(categoryIDs: [], includeUncategorized: true, tagIDs: [], includeUntagged: false)
        let uncategorizedPlaces = mockPlaces.filter { $0.category == nil }
        fetchResult = try! await placeRepo.fetch(filter)
        #expect(fetchResult.count == uncategorizedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == uncategorizedPlaces.map({ $0.id }).sorted())
    }
    
    @MainActor
    @Test func includeUntagged() async throws {
        let (mockPlaces, _, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()
        
        // Check includeUntagged filtering
        let filter = PlaceFilter(categoryIDs: [], includeUncategorized: false, tagIDs: [], includeUntagged: true)
        let untaggedPlaces = mockPlaces.filter { $0.tags.count == 0 }
        fetchResult = try! await placeRepo.fetch(filter)
        #expect(fetchResult.count == untaggedPlaces.count)
        #expect(fetchResult.map({ $0.id }).sorted() == untaggedPlaces.map({ $0.id }).sorted())
    }
    
    @MainActor
    @Test func categoryFiltering() async throws {
        let (mockPlaces, _, mockCategories, placeRepo) = createDataSet()
        var fetchResult = [Place]()
        
        // Check category filtering
        let filter1 = PlaceFilter(categoryIDs: [mockCategories[0].id], includeUncategorized: false, tagIDs: [], includeUntagged: false)
        fetchResult = try! await placeRepo.fetch(filter1)
        #expect(fetchResult.count == 2)
        var ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))
        
        let filter2 = PlaceFilter(categoryIDs: [mockCategories[1].id, mockCategories[4].id, mockCategories[5].id])
        fetchResult = try! await placeRepo.fetch(filter2)
        #expect(fetchResult.count == 4)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[2].id))
        #expect(ids.contains(mockPlaces[3].id))
        #expect(ids.contains(mockPlaces[4].id))
        #expect(ids.contains(mockPlaces[5].id))

        // Category combined with uncategorized
        let filter3 = PlaceFilter(categoryIDs: [mockCategories[1].id], includeUncategorized: true)
        fetchResult = try! await placeRepo.fetch(filter3)
        #expect(fetchResult.count == 5)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[4].id))
        #expect(ids.contains(mockPlaces[6].id))
        #expect(ids.contains(mockPlaces[7].id))
        #expect(ids.contains(mockPlaces[8].id))
        #expect(ids.contains(mockPlaces[9].id))
    }
    
    @MainActor
    @Test func tagAllFiltering() async throws {
        let (mockPlaces, mockTags, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()
        
        // Check tag all filtering
        let filter1 = PlaceFilter(tagIDs: [mockTags[8].id], selectedTagFilterPolicy: .all)
        fetchResult = try! await placeRepo.fetch(filter1)
        #expect(fetchResult.count == 3)
        var ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))
        #expect(ids.contains(mockPlaces[5].id))

        let filter2 = PlaceFilter(tagIDs: [mockTags[8].id, mockTags[10].id], selectedTagFilterPolicy: .all)
        fetchResult = try! await placeRepo.fetch(filter2)
        #expect(fetchResult.count == 2)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[5].id))

        // No place has every selected tag
        let filter3 = PlaceFilter(tagIDs: [mockTags[8].id, mockTags[9].id, mockTags[10].id], selectedTagFilterPolicy: .all)
        fetchResult = try! await placeRepo.fetch(filter3)
        #expect(fetchResult.count == 0)

        // includeUntagged is ignored for '.all' : no tags selected -> inactive filter, all places returned
        let filter4 = PlaceFilter(tagIDs: [], includeUntagged: true, selectedTagFilterPolicy: .all)
        #expect(filter4.isActive == false)
        #expect(filter4.filterCount == 0)
        fetchResult = try! await placeRepo.fetch(filter4)
        #expect(fetchResult.count == mockPlaces.count)

        // includeUntagged is ignored for '.all' : untagged places are not added
        let filter5 = PlaceFilter(tagIDs: [mockTags[8].id], includeUntagged: true, selectedTagFilterPolicy: .all)
        #expect(filter5.filterCount == 1)
        fetchResult = try! await placeRepo.fetch(filter5)
        #expect(fetchResult.count == 3)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))
        #expect(ids.contains(mockPlaces[5].id))
    }
    
    @MainActor
    @Test func tagAnyFiltering() async throws {
        let (mockPlaces, mockTags, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()

        // Check tag any filtering
        let filter1 = PlaceFilter(tagIDs: [mockTags[8].id], selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter1)
        #expect(fetchResult.count == 3)
        var ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))
        #expect(ids.contains(mockPlaces[5].id))

        let filter2 = PlaceFilter(tagIDs: [mockTags[8].id, mockTags[10].id], selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter2)
        #expect(fetchResult.count == 3)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))
        #expect(ids.contains(mockPlaces[5].id))

        // Tag combined with untagged
        let filter3 = PlaceFilter(tagIDs: [mockTags[1].id], includeUntagged: true, selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter3)
        #expect(fetchResult.count == 6)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[3].id))
        #expect(ids.contains(mockPlaces[4].id))
        #expect(ids.contains(mockPlaces[6].id))
        #expect(ids.contains(mockPlaces[7].id))
        #expect(ids.contains(mockPlaces[8].id))
        #expect(ids.contains(mockPlaces[9].id))
    }
    
    @MainActor
    @Test func categoriesAndTags() async throws {
        let (mockPlaces, mockTags, mockCategories, placeRepo) = createDataSet()
        var fetchResult = [Place]()

        // Check tag any filtering
        let filter1 = PlaceFilter(categoryIDs: [mockCategories[5].id],
                                  tagIDs: [mockTags[1].id], selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter1)
        #expect(fetchResult.count == 1)
        var ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[3].id))

        let filter2 = PlaceFilter(categoryIDs: [mockCategories[0].id],
                                  tagIDs: [mockTags[8].id, mockTags[10].id], selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter2)
        #expect(fetchResult.count == 2)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))
        #expect(ids.contains(mockPlaces[1].id))

        let filter3 = PlaceFilter(categoryIDs: [mockCategories[0].id],
                                  tagIDs: [mockTags[8].id, mockTags[10].id], selectedTagFilterPolicy: .all)
        fetchResult = try! await placeRepo.fetch(filter3)
        #expect(fetchResult.count == 1)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[0].id))

        // Uncategorized and untagged: intersection
        let filter4 = PlaceFilter(includeUncategorized: true, includeUntagged: true)
        fetchResult = try! await placeRepo.fetch(filter4)
        #expect(fetchResult.count == 4)
        ids = fetchResult.map({ $0.id })
        #expect(ids.contains(mockPlaces[6].id))
        #expect(ids.contains(mockPlaces[7].id))
        #expect(ids.contains(mockPlaces[8].id))
        #expect(ids.contains(mockPlaces[9].id))
    }

    @MainActor
    @Test func unknownIDs() async throws {
        let (_, _, _, placeRepo) = createDataSet()
        var fetchResult = [Place]()

        // Ids matching no place (e.g. deleted tag / category still in filter)
        let filter1 = PlaceFilter(tagIDs: [UUID()], selectedTagFilterPolicy: .any)
        fetchResult = try! await placeRepo.fetch(filter1)
        #expect(fetchResult.count == 0)

        let filter2 = PlaceFilter(tagIDs: [UUID()], selectedTagFilterPolicy: .all)
        fetchResult = try! await placeRepo.fetch(filter2)
        #expect(fetchResult.count == 0)

        let filter3 = PlaceFilter(categoryIDs: [UUID()])
        fetchResult = try! await placeRepo.fetch(filter3)
        #expect(fetchResult.count == 0)
    }

    @Test func isActive() {
        #expect(PlaceFilter().isActive == false)
        #expect(PlaceFilter(selectedTagFilterPolicy: .all).isActive == false)
        #expect(PlaceFilter(categoryIDs: [UUID()]).isActive)
        #expect(PlaceFilter(includeUncategorized: true).isActive)
        #expect(PlaceFilter(tagIDs: [UUID()]).isActive)
        #expect(PlaceFilter(includeUntagged: true, selectedTagFilterPolicy: .any).isActive)
        #expect(PlaceFilter(includeUntagged: true, selectedTagFilterPolicy: .all).isActive == false)
    }

    @Test func filterCount() {
        let filterAny = PlaceFilter(categoryIDs: [UUID()], includeUncategorized: true,
                                    tagIDs: [UUID(), UUID()], includeUntagged: true,
                                    selectedTagFilterPolicy: .any)
        #expect(filterAny.filterCount == 5)

        // includeUntagged is ignored for '.all'
        let filterAll = PlaceFilter(categoryIDs: filterAny.categoryIDs, includeUncategorized: true,
                                    tagIDs: filterAny.tagIDs, includeUntagged: true,
                                    selectedTagFilterPolicy: .all)
        #expect(filterAll.filterCount == 4)
    }
}
