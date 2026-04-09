//
//  PlaceFilter.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/4/26.
//

import Foundation

struct PlaceFilter {
    var groupIDs: Set<UUID> = []
    var includeUngrouped: Bool = false
    var tagIDs: Set<UUID> = []
    var includeUntagged: Bool = false

    var isActive: Bool {
        !groupIDs.isEmpty || includeUngrouped || !tagIDs.isEmpty || includeUntagged
    }
}

extension PlaceFilter {
    func matches(_ place: PlaceEntity) -> Bool {
        guard isActive else { return true }
        // Check if place matches group filtering
        if let group = place.group {
            if groupIDs.contains(group.id) {
                return true
            }
        } else {
            if includeUngrouped {
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
