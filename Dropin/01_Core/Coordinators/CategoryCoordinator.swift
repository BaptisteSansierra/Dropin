//
//  CategoryCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class CategoryCoordinator: PlaceNavigationCoordinator {

    var path: [CategoryNavigationItem] = [] {
        didSet {
            //Log.info("GROUP COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    // MARK: navigation methods
    
    func pushPlaceEditView(placeRef: PlaceUIModelRef) {
        path.append(.groupPlaceEdit(placeRef: placeRef))
    }

    func pushCategoryDetailsView(categoryId: UUID) {
        path.append(.groupDetails(categoryId: categoryId))
    }

    func pushCategoryMapView(categoryId: UUID, places: [PlaceUIModelRef]) {
        path.append(.groupMap(categoryId: categoryId, places: places))
    }

    func pushLookupPlacesEditView(placeRef: PlaceUIModelRef) {
        path.append(.lookupPlacesEditView(placeRef: placeRef))
    }

    func pushUndefinedDummyView() {
        path.append(.undefinedDummyView)
    }
    
    func popToRoot() {
        path.removeAll()
    }

    func pop() {
        _ = path.popLast()
    }
}

enum CategoryNavigationItem: Hashable {
    case groupDetails(categoryId: UUID)
    case groupMap(categoryId: UUID, places: [PlaceUIModelRef])
    case groupPlaceEdit(placeRef: PlaceUIModelRef)
    case lookupPlacesEditView(placeRef: PlaceUIModelRef)
    // development
    case undefinedDummyView
}
