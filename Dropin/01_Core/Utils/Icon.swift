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

/*
struct Icon: Codable, Identifiable, Hashable {
    
    enum Source: String, Codable {
        case sf, fa, invalid
    }
    
    let id: String
    let source: Source
    let name: String
    
    var rawValue: String {
        "\(source.rawValue):\(name)"
    }
    var isValid: Bool {
        name.count >= 0 && source != .invalid
    }
    
    init(source: Source, name: String) {
        self.id = UUID().uuidString
        self.source = source
        self.name = name
    }
    
    init(_ rawValue: String) {
        self.id = "\(UUID().uuidString)-\(rawValue)"
        let parts = rawValue.split(separator: ":", maxSplits: 1)
        if parts.count == 2, let source = Source(rawValue: String(parts[0])) {
            self.source = source
            self.name = String(parts[1])
        } else {
            self.source = .invalid
            self.name = rawValue
        }
    }    
}
*/

