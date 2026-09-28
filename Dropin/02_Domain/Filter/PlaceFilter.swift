//
//  PlaceFilter.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/4/26.
//

import Foundation

struct PlaceFilter {
    var categoryIDs: Set<UUID> = []
    var includeUncategorized: Bool = false
    var tagIDs: Set<UUID> = []
    var includeUntagged: Bool = false

    var isActive: Bool {
        !categoryIDs.isEmpty || includeUncategorized || !tagIDs.isEmpty || includeUntagged
    }
}

extension PlaceFilter {
    func matches(_ place: Place) -> Bool {
        guard isActive else { return true }
        // Check if place matches category filtering
        if let category = place.category {
            if categoryIDs.contains(category.id) {
                return true
            }
        } else {
            if includeUncategorized {
                return true
            }
        }
        // Check if place matches tag filtering
        if place.tags.count == 0 && includeUntagged {
            return true
        }
        for tag in place.tags {
            if tagIDs.contains(tag.id) {
                return true
            }
        }
        return false
    }
}
