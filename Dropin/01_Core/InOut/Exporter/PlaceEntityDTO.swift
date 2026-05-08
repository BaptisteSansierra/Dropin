//
//  PlaceEntityDTO.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation
import CoreLocation

// Data transfer object: same properties as PlaceEntity but relationship refers to object ids
struct PlaceEntityDTO: Decodable {
    
    let id: UUID
    var name: String
    var coordinates: CLLocationCoordinate2D
    var address: String
    var address2: String
    var tagIds: [UUID]
    var groupId: UUID?
    var images: [UUID]
    var icon: Icon?
    var rating: Float?
    var phone: [String]
    var email: [String]
    var url: [String]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: PlaceEntity.CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.coordinates = try c.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
        self.address = try c.decode(String.self, forKey: .address)
        self.address2 = try c.decode(String.self, forKey: .address2)
        self.tagIds = try c.decode([UUID].self, forKey: .tagIds)
        self.groupId = try c.decodeIfPresent(UUID.self, forKey: .groupId)
        self.images = []  // Not supported
        self.icon = try c.decodeIfPresent(Icon.self, forKey: .icon)
        self.rating = try c.decodeIfPresent(Float.self, forKey: .rating)
        self.phone = try c.decode([String].self, forKey: .phone)
        self.email = try c.decode([String].self, forKey: .email)
        self.url = try c.decode([String].self, forKey: .url)
        self.notes = try c.decodeIfPresent(String.self, forKey: .notes)
        
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        self.deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
}
