//
//  MarkerListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/3/26.
//

import SwiftUI

@MainActor
@Observable class MarkerListViewModel {
    
    //var position = ScrollPosition(edge: .bottom)
    //var confirmed = false
    var nullable: Bool
    
    init(nullable: Bool) {
        self.nullable = nullable
    }
}
