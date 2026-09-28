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
    private(set) var categories: [Category]
    private(set) var tags: [Tag]
    private(set) var places: [Place]
    
    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case tags
        // Wire key stays "groups" — old exported .dropin v1 files use it, and
        // this is a stable on-disk format, unlike the in-app Category rename.
        case categories = "groups"
        case places
    }
    
    #if DEBUG
    #endif
    
    init(exportedAt: Date,
         places: [Place],
         categories: [Category],
         tags: [Tag]) {
        self.version = CURRENT_VERSION
        self.exportedAt = exportedAt
        self.places = places
        self.categories = categories
        self.tags = tags
    }
    
    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(exportedAt, forKey: .exportedAt)
        try c.encode(categories, forKey: .categories)
        try c.encode(tags, forKey: .tags)
        try c.encode(places, forKey: .places)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.version = -1
        self.exportedAt = Date.distantFuture
        self.places = []
        self.categories = []
        self.tags = []

        // Check version
        self.version = try container.decode(Int.self, forKey: .version)
        Log.info("Decoding dropin data v.\(version)")
        if version == 1 {
            try loadV1(container)
        } else {
            // let the caller (likely ImportDropinService.decode) decide what an unrecognized version means
        }
    }
    
    private mutating func loadV1(_ container: KeyedDecodingContainer<CodingKeys>) throws {
        self.exportedAt = try container.decode(Date.self, forKey: .exportedAt)

        self.tags = try container.decode([Tag].self, forKey: .tags)
        self.categories = try container.decode([Category].self, forKey: .categories)
        let placesDTO = try container.decode([PlaceDTO].self, forKey: .places)

        // Create places
        self.places = placesDTO.map({ placeDTO in
            let placeTags = tags.filter({ placeDTO.tagIds.contains($0.id) })
            var placeCategory: Category? = nil
            if let categoryId = placeDTO.categoryId {
                placeCategory = categories.first(where: { $0.id == categoryId })
            }
            return Place(id: placeDTO.id,
                               name: placeDTO.name,
                               coordinates: placeDTO.coordinates,
                               address: placeDTO.address,
                               address2: placeDTO.address2,
                               tags: placeTags,
                               category: placeCategory,
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
