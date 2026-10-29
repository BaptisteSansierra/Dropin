//
//  PlaceFilter.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/4/26.
//

import Foundation

struct PlaceFilter {
    
    enum TagFilterPolicy: String, CaseIterable {
        case any
        case all
    }

    var categoryIDs: Set<UUID> = []
    var includeUncategorized: Bool = false
    var tagIDs: Set<UUID> = []
    var includeUntagged: Bool = false
    var selectedTagFilterPolicy: TagFilterPolicy = .any

    /// includeUntagged is ignored for '.all'
    private var appliesUntagged: Bool {
        includeUntagged && selectedTagFilterPolicy == .any
    }

    var isActive: Bool {
        !categoryIDs.isEmpty || includeUncategorized || !tagIDs.isEmpty || appliesUntagged
    }
    
    var filterCount: Int {
        var count = categoryIDs.count + tagIDs.count
        if includeUncategorized {
            count += 1
        }
        if appliesUntagged {
            count += 1
        }
        return count
    }
}

extension PlaceFilter {
    
    func matches(_ place: Place) -> Bool {
        guard isActive else { return true }
        return matchesCategories(place) && matchesTags(place)
    }
    
    private func matchesCategories(_ place: Place) -> Bool {
        // First check if category filtering is active
        guard categoryIDs.count > 0 || includeUncategorized else { return true }
        if let category = place.category {
            if categoryIDs.contains(category.id) {
                return true
            }
        } else if includeUncategorized {
            return true
        }
        return false
    }
    
    private func matchesTags(_ place: Place) -> Bool {
        // First check if tag filtering is active
        guard tagIDs.count > 0 || appliesUntagged else { return true }
        switch selectedTagFilterPolicy {
            case .all:
                return matchesAllTags(place)
            case .any:
                return matchesAnyTags(place)
        }
    }

    private func matchesAllTags(_ place: Place) -> Bool {
        // includeUntagged is ignored for '.all'
        let placeTagIds = place.tags.map { $0.id }
        for tagId in tagIDs {
            if !placeTagIds.contains(tagId) {
                return false
            }
        }
        return true
    }
    
    private func matchesAnyTags(_ place: Place) -> Bool {
        if place.tags.count == 0 && appliesUntagged {
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
