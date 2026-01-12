//
//  MainCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/1/26.
//

import SwiftUI

@MainActor
@Observable class MainCoordinator {
    
    var path: [NavigationItem] = [] {
        didSet {
            print("COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    func pushPlaceDetailsView(placeId: String, editMode: PlaceEditMode = .none) {
        path.append(NavigationItem.placeDetailsView(placeId: placeId, editMode: editMode))
    }
    
    func pushLookupPlacesView() {
        path.append(NavigationItem.lookupPlacesView)
    }
    
    func pushUndefinedDummyView() {
        path.append(NavigationItem.undefinedDummyView)
    }
    
    func pop() {
        _ = path.popLast()
    }
}

enum NavigationItem: Hashable {
    case placeDetailsView(placeId: String, editMode: PlaceEditMode)
    case lookupPlacesView
    
    case undefinedDummyView
}
