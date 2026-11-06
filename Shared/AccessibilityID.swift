//
//  AccessibilityID.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/11/26.
//

/// Accessibility identifiers shared with the UI test targets (Shared/ is compiled in Dropin + DropinScreenshots).
/// "screen.element" naming; only add what a test needs to find or wait for.
enum AccessibilityID {
    enum Navigation {
        static let burger = "navigation.burger"
    }
    enum Places {
        static let map = "places.map"
        static let list = "places.list"
        static let mapTab = "places.tab.map"
        static let listTab = "places.tab.list"
        static let filterButton = "places.filterButton"
    }
    enum Settings {
        static let importMenu = "settings.importMenu"
    }
    enum ImportStatus {
        static let complete = "importStatus.complete"
    }
    enum PlaceHeader {
        static let name = "placeHeader.name"
    }
    enum QuickCreate {
        static let sheet = "quickCreate.sheet"
        static let addTags = "quickCreate.addTags"
        static let chooseCategory = "quickCreate.chooseCategory"
    }
    enum TagSelector {
        static let sheet = "tagSelector.sheet"
    }
    enum PlaceSheet {
        static let root = "placeSheet.root"
    }
    enum PlaceFilter {
        static let sheet = "placeFilter.sheet"
        static let apply = "placeFilter.apply"
        static let tagPolicy = "placeFilter.tagPolicy"
    }
    enum Sidebar {
        static let places = "settings.places"
        static let categories = "settings.categories"
        static let tags = "settings.tags"
        static let settings = "sidebar.settings"
    }
}
