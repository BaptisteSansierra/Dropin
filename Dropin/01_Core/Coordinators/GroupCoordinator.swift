//
//  GroupCoordinador.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class GroupCoordinator {
    
    var path: [GroupNavigationItem] = [] {
        didSet {
            Log.info("GROUP COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    func pushGroupDetailsView(groupId: UUID) {
        path.append(GroupNavigationItem.groupDetails(groupId: groupId))
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
    // development
    case undefinedDummyView
}
