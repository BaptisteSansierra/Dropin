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
        case icon
        case createdAt
        case rating
        case phone
        case email
        case url
        case notes
        case images
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
        try c.encode(group?.id, forKey: .groupId)
        try c.encode(icon, forKey: .icon)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(rating, forKey: .rating)
        try c.encode(phone, forKey: .phone)
        try c.encode(email, forKey: .email)
        try c.encode(url, forKey: .url)
        try c.encode(notes, forKey: .notes)
        
        // FIXME: encode empty array for images
        try c.encode([UUID](), forKey: .images)
        
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }
    
    /*
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.coordinates = try c.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
        self.address = try c.decode(String.self, forKey: .address)
        self.address2 = try c.decode(String.self, forKey: .address2)

        self.tags = []
        self.group = nil

        //let tagIds = try c.decode([UUID].self, forKey: .tagIds)
        //let groupId = try c.decodeIfPresent(UUID.self, forKey: .groupId)
        
        self.icon = try c.decode(Icon.self, forKey: .icon)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.rating = try c.decodeIfPresent(Float.self, forKey: .rating)
        self.phone = try c.decode([ContactItem].self, forKey: .phone)
        self.email = try c.decode([ContactItem].self, forKey: .email)
        self.url = try c.decode([ContactItem].self, forKey: .url)
        self.notes = try c.decode(String.self, forKey: .notes)
        
        // TODO: images should not be stored within Place object...
        self.images = []
        //let images = try c.decode([Data].self, forKey: .images)
        
        self.deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
     */
}
