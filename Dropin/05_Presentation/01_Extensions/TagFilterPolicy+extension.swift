//
//  TagFilterPolicy+extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/10/26.
//

import SwiftUI

extension PlaceFilter.TagFilterPolicy {
    
    var displayName: LocalizedStringKey {
        switch self {
            case .all:
                return "place_filter_view.tag.all"
            case .any:
                return "place_filter_view.tag.any"
        }
    }
}
