//
//  DropinInOut.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

struct DropinInOut: Codable, Sendable {

    private let CURRENT_VERSION: Int = 1

    private(set) var version: Int
    private(set) var exportedAt: Date
    private(set) var categories: [DropinCategoryDTO]
    private(set) var tags: [DropinTagDTO]
    private(set) var places: [DropinPlaceDTO]
    
    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case tags
        case categories
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
        self.places = places.map { DropinPlaceDTO($0) }
        self.categories = categories.map { DropinCategoryDTO($0) }
        self.tags = tags.map { DropinTagDTO($0) }
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
        self.tags = try container.decode([DropinTagDTO].self, forKey: .tags)
        self.categories = try container.decode([DropinCategoryDTO].self, forKey: .categories)
        self.places = try container.decode([DropinPlaceDTO].self, forKey: .places)
    }
}
