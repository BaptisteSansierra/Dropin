//
//  Icon.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/11/25.
//

import Foundation

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
