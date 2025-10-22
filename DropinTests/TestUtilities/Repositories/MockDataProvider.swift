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
        var mockPlaces = PlaceEntity.mockPlaces()
        let mockTags = TagEntity.mockTags()
        let mockGroups = GroupEntity.mockGroups()
        // link objects
        mockPlaces[0].group = mockGroups[0]
        mockPlaces[0].tags = [mockTags[8], mockTags[10], mockTags[13]]

        mockPlaces[1].group = mockGroups[0]
        mockPlaces[1].tags = [mockTags[8], mockTags[9], mockTags[13]]

        mockPlaces[2].group = mockGroups[4]
        mockPlaces[2].tags = [mockTags[6], mockTags[7]]

        mockPlaces[3].group = mockGroups[5]
        mockPlaces[3].tags = [mockTags[1]]

        mockPlaces[4].group = mockGroups[5]
        mockPlaces[4].tags = [mockTags[1]]

        mockPlaces[5].group = mockGroups[5]
        mockPlaces[5].tags = [mockTags[11], mockTags[12]]

        mockPlaces[6].group = mockGroups[7]
        mockPlaces[6].tags = [mockTags[9], mockTags[12]]

        mockPlaces[7].group = mockGroups[8]
        mockPlaces[7].tags = [mockTags[9]]

        mockPlaces[6].group = mockGroups[8]
        mockPlaces[6].tags = [mockTags[12], mockTags[14], mockTags[15]]

        return mockPlaces
    }
}
