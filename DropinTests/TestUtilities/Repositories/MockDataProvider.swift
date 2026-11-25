//
//  MockDataProvider.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

// LEGACY

#if false

import Foundation
@testable import Dropin

class MockDataProvider {
    func mockEntities() -> [Place] {
        let mockTags = Dropin.Tag.mockTags()
        let mockCategories = Dropin.Category.mockCategories()
        
        var mockPlaces = Place.mockPlaces()

        // link objects
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
                                    tags: [mockTags[1]],
                                    category: mockCategories[5])

        mockPlaces[5] = Place(other: mockPlaces[5],
                                    tags: [mockTags[11], mockTags[12]],
                                    category: mockCategories[5])

        mockPlaces[6] = Place(other: mockPlaces[6],
                                    tags: [mockTags[9], mockTags[12]],
                                    category: mockCategories[7])

        mockPlaces[7] = Place(other: mockPlaces[7],
                                    tags: [mockTags[8]],
                                    category: mockCategories[9])
        
        return mockPlaces
    }
}

#endif

