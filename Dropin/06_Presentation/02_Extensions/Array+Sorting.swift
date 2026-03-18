//
//  Array+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation

@MainActor
extension Array where Element == PlaceUI {
    func defaultSorted() -> [PlaceUI] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.creationDate < rhs.creationDate
            }
            return lhs.name < rhs.name
        }
    }
}

@MainActor
extension Array where Element == GroupUI {
    func defaultSorted() -> [GroupUI] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.creationDate < rhs.creationDate
            }
            return lhs.name < rhs.name
        }
    }
}

@MainActor
extension Array where Element == TagUI {
    func defaultSorted() -> [TagUI] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.creationDate < rhs.creationDate
            }
            return lhs.name < rhs.name
        }
    }
}
