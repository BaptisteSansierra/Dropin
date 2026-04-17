//
//  TagEntity+Codable.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

extension TagEntity: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case createdAt
        case deletedAt
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(color, forKey: .color)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
    
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.color = try c.decode(String.self, forKey: .color)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}

