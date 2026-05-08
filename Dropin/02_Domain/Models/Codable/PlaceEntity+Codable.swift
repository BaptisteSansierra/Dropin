//
//  PlaceEntity+Codable.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation
import CoreLocation
import ContactFieldKit

extension PlaceEntity: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinates
        case address
        case address2
        case tagIds
        case groupId
        case images
        case icon
        case rating
        case phone
        case email
        case url
        case notes
        case createdAt
        case updatedAt
        case deletedAt
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(coordinates, forKey: .coordinates)
        try c.encode(address, forKey: .address)
        try c.encode(address2, forKey: .address2)
        let tagIds = tags.map { $0.id }
        try c.encode(tagIds, forKey: .tagIds)
        try c.encodeIfPresent(group?.id, forKey: .groupId)
        try c.encode([UUID()], forKey: .images)      // Not supported, export empty array
        try c.encodeIfPresent(icon, forKey: .icon)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encode(phone, forKey: .phone)
        try c.encode(email, forKey: .email)
        try c.encode(url, forKey: .url)
        try c.encodeIfPresent(notes, forKey: .notes)
        // Dates
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
}
