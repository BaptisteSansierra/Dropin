//
//  DropinExport.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

struct DropinExport: Codable {
    
    let currentVersion: Int = 1
    let exportedAt: Date
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
        self.exportedAt = exportedAt
        self.places = places
        self.groups = groups
        self.tags = tags
    }
    
    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentVersion, forKey: .version)
        try c.encode(exportedAt, forKey: .exportedAt)
        try c.encode(groups, forKey: .groups)
        try c.encode(tags, forKey: .tags)
        try c.encode(places, forKey: .places)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let version = try container.decode(Int.self, forKey: .version)
        guard version <= currentVersion else {
            throw CodingError.decodingUnknownVersion(version: version)
        }
        Log.info("Importing dropin data v.\(version)")
        
        self.exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        let tagsDTO = try container.decode([TagEntity].self, forKey: .tags)
        let groupsDTO = try container.decode([GroupEntity].self, forKey: .groups)
        let placesDTO = try container.decode([PlaceEntityDTO].self, forKey: .places)
        
        self.places = []
        self.groups = []
        self.tags = []
        
        // Create groups
        self.groups = groupsDTO.map({ groupDTO in
            return GroupEntity(id: groupDTO.id,
                               name: groupDTO.name,
                               color: groupDTO.color,
                               icon: groupDTO.icon,
                               places: [],
                               createdAt: groupDTO.createdAt,
                               deletedAt: groupDTO.deletedAt)
        })
        
        // Create tags
        self.tags = tagsDTO.map({ tagDTO in
            return TagEntity(id: tagDTO.id,
                             name: tagDTO.name,
                             color: tagDTO.color,
                             places: [],
                             createdAt: tagDTO.createdAt,
                             deletedAt: tagDTO.deletedAt)
        })
        
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
                               icon: placeDTO.icon,
                               rating: placeDTO.rating,
                               phone: placeDTO.phone,
                               email: placeDTO.email,
                               url: placeDTO.url,
                               notes: placeDTO.notes,
                               images: [],
                               createdAt: placeDTO.createdAt,
                               deletedAt: placeDTO.deletedAt)
        })
        
        /*
        // Link groups to places
        groups = groups.map({ group in
            let places = self.places.filter {
                guard let placeGroup = $0.group else { return false }
                return placeGroup.id == group.id
            }
            return GroupEntity(id: group.id,
                               name: group.name,
                               color: group.color,
                               icon: group.icon,
                               places: places,
                               createdAt: group.createdAt,
                               deletedAt: group.deletedAt)
        })
        
        // Link tags to places
        tags = tags.map({ tag in
            let places = self.places.filter { place in
                place.tags.first(where: { $0.id == tag.id }) != nil
            }
            return TagEntity(id: tag.id,
                             name: tag.name,
                             color: tag.color,
                             places: places,
                             createdAt: tag.createdAt,
                             deletedAt: tag.deletedAt)
        })
         */
    }
}
