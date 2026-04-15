//
//  PlaceFilter+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/4/26.
//

import Foundation

extension PlaceFilter {

    @MainActor
    func apply(_ places: [PlaceUI]) -> [PlaceUI] {
        places.filter { matches( PlaceMapper.toDomain($0) ) }
    }
}
