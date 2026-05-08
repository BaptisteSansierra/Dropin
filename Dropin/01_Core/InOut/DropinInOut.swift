//
//  DropinInOut.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

struct DropinInOut: Codable {

    private let CURRENT_VERSION: Int = 1

    private(set) var version: Int
    private(set) var exportedAt: Date
    private(set) var groups: [GroupEntity]
    private(set) var tags: [TagEntity]
    private(set) var places: [PlaceEntity]
    
    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case tags
        case groups
        case places
    }
    
    init(exportedAt: Date,
         places: [PlaceEntity],
         groups: [GroupEntity],
         tags: [TagEntity]) {
        self.version = CURRENT_VERSION
        self.exportedAt = exportedAt
        self.places = places
        self.groups = groups
        self.tags = tags
    }
    
    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(exportedAt, forKey: .exportedAt)
        try c.encode(groups, forKey: .groups)
        try c.encode(tags, forKey: .tags)
        try c.encode(places, forKey: .places)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.version = -1
        self.exportedAt = Date.distantFuture
        self.places = []
        self.groups = []
        self.tags = []

        // Check version
        self.version = try container.decode(Int.self, forKey: .version)
        Log.info("Importing dropin data v.\(version)")
        if version == 1 {
            try loadV1(container)
        } else {
            fatalError("This version '\(version)' is not handled")
        }
    }
    
    private mutating func loadV1(_ container: KeyedDecodingContainer<CodingKeys>) throws {
        self.exportedAt = try container.decode(Date.self, forKey: .exportedAt)

        self.tags = try container.decode([TagEntity].self, forKey: .tags)
        self.groups = try container.decode([GroupEntity].self, forKey: .groups)
        let placesDTO = try container.decode([PlaceEntityDTO].self, forKey: .places)

        // Create places
        self.places = placesDTO.map({ placeDTO in
            let placeTags = tags.filter({ placeDTO.tagIds.contains($0.id) })
            var placeGroup: GroupEntity? = nil
            if let groupId = placeDTO.groupId {
                placeGroup = groups.first(where: { $0.id == groupId })
            }
            return PlaceEntity(id: placeDTO.id,
                               name: placeDTO.name,
                               coordinates: placeDTO.coordinates,
                               address: placeDTO.address,
                               address2: placeDTO.address2,
                               tags: placeTags,
                               group: placeGroup,
                               images: [],
                               icon: placeDTO.icon,
                               rating: placeDTO.rating,
                               phone: placeDTO.phone,
                               email: placeDTO.email,
                               url: placeDTO.url,
                               notes: placeDTO.notes,
                               createdAt: placeDTO.createdAt,
                               updatedAt: placeDTO.updatedAt,
                               deletedAt: placeDTO.deletedAt)
        })
    }
}
