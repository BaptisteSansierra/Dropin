//
//  PlaceContext.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/25.
//

import SwiftUI

@MainActor
@Observable class PlaceContext {
    
    var place: PlaceEntity
    
    init(place: PlaceEntity) {
        self.place = place
    }
}


