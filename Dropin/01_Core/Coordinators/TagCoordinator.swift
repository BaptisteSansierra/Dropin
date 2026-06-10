//
//  TagCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class TagCoordinator: PlaceNavigationCoordinator {
    
    var path: [TagNavigationItem] = [] {
        didSet {
            Log.info("TAG COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    // MARK: navigation methods
    func pushPlaceEditView(placeRef: PlaceUIRef) {
        path.append(TagNavigationItem.tagPlace(placeRef: placeRef))
    }

    func pushTagDetailsView(tagId: UUID) {
        path.append(TagNavigationItem.tagDetails(tagId: tagId))
    }
    
    func pushTagMapView(tagId: UUID) {
        path.append(TagNavigationItem.tagMap(tagId: tagId))
    }

    func pushUndefinedDummyView() {
        path.append(TagNavigationItem.undefinedDummyView)
    }
    
    func pop() {
        _ = path.popLast()
    }
}

enum TagNavigationItem: Hashable {
    case tagDetails(tagId: UUID)
    case tagMap(tagId: UUID)
    case tagPlace(placeRef: PlaceUIRef)
    // development
    case undefinedDummyView
}
