//
//  TagCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class TagCoordinator: PlaceNavigationCoordinator {
    
    var path: [TagNavigationItem] = []
    
    // MARK: navigation methods
    func pushPlaceEditView(placeRef: PlaceUIModelRef) {
        path.append(TagNavigationItem.tagPlaceEdit(placeRef: placeRef))
    }

    func pushTagDetailsView(tagId: UUID) {
        path.append(TagNavigationItem.tagDetails(tagId: tagId))
    }
    
    func pushTagMapView(tagId: UUID, places: [PlaceUIModelRef]) {
        path.append(TagNavigationItem.tagMap(tagId: tagId, places: places))
    }

    func pushLookupPlacesEditView(placeRef: PlaceUIModelRef) {
        path.append(TagNavigationItem.lookupPlacesEditView(placeRef: placeRef))
    }

    func pushUndefinedDummyView() {
        path.append(TagNavigationItem.undefinedDummyView)
    }
        
    func popToRoot() {
        path.removeAll()
    }

    func pop() {
        _ = path.popLast()
    }
}

enum TagNavigationItem: Hashable {
    case tagDetails(tagId: UUID)
    case tagMap(tagId: UUID, places: [PlaceUIModelRef])
    case tagPlaceEdit(placeRef: PlaceUIModelRef)
    case lookupPlacesEditView(placeRef: PlaceUIModelRef)
    // development
    case undefinedDummyView
}
