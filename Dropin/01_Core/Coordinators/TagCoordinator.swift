//
//  TagCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/1/26.
//

import SwiftUI

@MainActor
@Observable class TagCoordinator {
    
    var path: [TagNavigationItem] = [] {
        didSet {
            print("TAG COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
        }
    }
    
    func pushTagDetailsView(tagId: String) {
        path.append(TagNavigationItem.tagDetails(tagId: tagId))
    }
    
    func pushUndefinedDummyView() {
        path.append(TagNavigationItem.undefinedDummyView)
    }
    
    func pop() {
        _ = path.popLast()
    }
}

enum TagNavigationItem: Hashable {
    case tagDetails(tagId: String)
    // development
    case undefinedDummyView
}
