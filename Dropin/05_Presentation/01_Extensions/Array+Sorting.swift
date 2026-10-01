//
//  Array+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation

@MainActor
extension Array where Element == PlaceUIModel {
    func defaultSorted() -> [PlaceUIModel] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.name < rhs.name
        }
    }
}

@MainActor
extension Array where Element == CategoryUIModel {
    func defaultSorted() -> [CategoryUIModel] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.name < rhs.name
        }
    }
}

@MainActor
extension Array where Element == TagUIModel {
    func defaultSorted() -> [TagUIModel] {
        sorted { lhs, rhs in
            guard lhs.name != rhs.name else {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.name < rhs.name
        }
    }
}
