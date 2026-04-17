//
//  PlaceEntityDTO.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation
import ContactFieldKit
import CoreLocation

struct PlaceEntityDTO: Decodable {
    
    let id: UUID
    var name: String
    var coordinates: CLLocationCoordinate2D
    var address: String
    var address2: String
    var tagIds: [UUID]
    var groupId: UUID?
    var icon: Icon?
    var createdAt: Date
    var rating: Float?
    var phone: [ContactItem]
    var email: [ContactItem]
    var url: [ContactItem]
    var notes: String?
    var images: [Data]
    var deletedAt: Date? = nil
    
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: PlaceEntity.CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.coordinates = try c.decode(CLLocationCoordinate2D.self, forKey: .coordinates)
        self.address = try c.decode(String.self, forKey: .address)
        self.address2 = try c.decode(String.self, forKey: .address2)

        self.tagIds = try c.decode([UUID].self, forKey: .tagIds)
        self.groupId = try c.decodeIfPresent(UUID.self, forKey: .groupId)

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
}
