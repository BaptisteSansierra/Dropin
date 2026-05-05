//
//  DropinImporter.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

/*
@MainActor
class DropinImporter {
    
    private let url: URL
    private let fetchPlaces: FetchPlaces
    private let fetchGroups: FetchGroups
    private let fetchTags: FetchTags
    private var fetched: Bool = false

    private var contentGroups: [GroupEntity] = []
    private var contentTags: [TagEntity] = []
    private var contentPlaces: [PlaceEntity] = []

    init(url: URL,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags) {
        self.url = url
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
    }

    func fetchData() async throws {
        let data = try Data(contentsOf: url)

        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(DropinInOut.self, from: data)

        async let placesTask = fetchPlaces()
        async let groupsTask = fetchGroups()
        async let tagsTask = fetchTags()
        
        let (places, groups, tags) = try await (placesTask, groupsTask, tagsTask)

        contentGroups = importData.groups
        contentTags = importData.tags
        contentPlaces = importData.places
        
        fetched = true
    }

    func execute() async throws {
        guard fetched else { return }
    }
}
*/
