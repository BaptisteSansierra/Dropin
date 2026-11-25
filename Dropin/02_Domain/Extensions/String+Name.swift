//
//  String+Name.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/11/26.
//

import Foundation

/// Entity names (places, categories, tags…) rules:
///  - stored without surrounding whitespaces: `trimmedName`
///  - compared case-insensitive, without surrounding whitespaces: `nameKey`
extension String {

    /// Name as stored: "  Mapstr " → "Mapstr"
    var trimmedName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Name as compared: "  Mapstr " and "mapstr" share the same key
    var nameKey: String {
        trimmedName.lowercased()
    }
}

extension Array where Element == Tag {
    /// First active tag named `name`, compared with `nameKey`
    func firstActive(named name: String) -> Tag? {
        let key = name.nameKey
        return first { $0.isActive && $0.name.nameKey == key }
    }
}

extension Array where Element == Category {
    /// First active category named `name`, compared with `nameKey`
    func firstActive(named name: String) -> Category? {
        let key = name.nameKey
        return first { $0.isActive && $0.name.nameKey == key }
    }
}
