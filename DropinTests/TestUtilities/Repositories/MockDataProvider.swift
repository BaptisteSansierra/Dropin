//
//  MockDataProvider.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

class MockDataProvider {
    func mockEntities() -> [PlaceEntity] {
        let mockTags = TagEntity.mockTags()
        let mockGroups = GroupEntity.mockGroups()
        
        var mockPlaces = PlaceEntity.mockPlaces()

        // link objects
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
                                    tags: [mockTags[1]],
                                    group: mockGroups[5])

        mockPlaces[5] = PlaceEntity(other: mockPlaces[5],
                                    tags: [mockTags[11], mockTags[12]],
                                    group: mockGroups[5])

        mockPlaces[6] = PlaceEntity(other: mockPlaces[6],
                                    tags: [mockTags[9], mockTags[12]],
                                    group: mockGroups[7])

        mockPlaces[7] = PlaceEntity(other: mockPlaces[7],
                                    tags: [mockTags[8]],
                                    group: mockGroups[9])
        
        return mockPlaces
    }
}
