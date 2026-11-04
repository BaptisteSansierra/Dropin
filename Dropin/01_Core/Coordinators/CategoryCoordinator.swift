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
        path.append(CategoryNavigationItem.groupPlace(placeRef: placeRef))
    }

    func pushCategoryDetailsView(categoryId: UUID) {
        path.append(CategoryNavigationItem.groupDetails(categoryId: categoryId))
    }

    func pushCategoryMapView(categoryId: UUID) {
        path.append(CategoryNavigationItem.groupMap(categoryId: categoryId))
    }

    func pushUndefinedDummyView() {
        path.append(CategoryNavigationItem.undefinedDummyView)
    }
    
    func pop() {
        _ = path.popLast()
    }
}

enum CategoryNavigationItem: Hashable {
    case groupDetails(categoryId: UUID)
    case groupMap(categoryId: UUID)
    case groupPlace(placeRef: PlaceUIModelRef)
    // development
    case undefinedDummyView
}
