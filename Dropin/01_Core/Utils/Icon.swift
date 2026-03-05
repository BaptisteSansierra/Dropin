//
//  Icon.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/11/25.
//

import Foundation

enum Icon: RawRepresentable, Identifiable, Hashable {
    
    case sf(String)
    case fa(String)
    
    // MARK: - computed properties
    var rawValue: String {
        return "\(source):\(name)"
    }
    
    var id: String {
        return self.rawValue
    }
    
    var name: String {
        switch self {
            case .sf(let name):
                return name
            case .fa(let name):
                return name
        }
    }
    
    // MARK: - private computed properties
    private var source: String {
        switch self {
            case .sf: return "sf"
            case .fa: return "fa"
        }
    }
    
    // MARK: - init
    init?(rawValue: String) {
        let parts = rawValue.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        guard parts[1].count > 0 else { return nil }
        if String(parts[0]) == "sf" {
            self = .sf(String(parts[1]))
        } else if String(parts[0]) == "fa" {
            self = .fa(String(parts[1]))
        } else {
            return nil
        }
    }
}

extension Icon: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Icon(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid Icon")
        }
        self = value
    }
}
