//
//  GroupCoordinador.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class GroupCoordinator: PlaceNavigationCoordinator {

    var path: [GroupNavigationItem] = [] {
        didSet {
            Log.info("GROUP COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    // MARK: navigation methods
    
    func pushPlaceEditView(placeRef: PlaceUIRef) {
        path.append(GroupNavigationItem.groupPlace(placeRef: placeRef))
    }

    func pushGroupDetailsView(groupId: UUID) {
        path.append(GroupNavigationItem.groupDetails(groupId: groupId))
    }

    func pushGroupMapView(groupId: UUID) {
        path.append(GroupNavigationItem.groupMap(groupId: groupId))
    }

    func pushUndefinedDummyView() {
        path.append(GroupNavigationItem.undefinedDummyView)
    }
    
    func pop() {
        _ = path.popLast()
    }
}

enum GroupNavigationItem: Hashable {
    case groupDetails(groupId: UUID)
    case groupMap(groupId: UUID)
    case groupPlace(placeRef: PlaceUIRef)
    // development
    case undefinedDummyView
}
