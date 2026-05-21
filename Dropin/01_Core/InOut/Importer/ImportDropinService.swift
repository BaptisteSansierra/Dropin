//
//  ImportDropinService.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
struct ImportDropinService: ImportServiceProtocol {
    
    private let upsertPlace: UpsertPlace
    private let upsertGroup: UpsertGroup
    private let upsertTag: UpsertTag
    
    init(upsertPlace: UpsertPlace, upsertGroup: UpsertGroup, upsertTag: UpsertTag) {
        self.upsertPlace = upsertPlace
        self.upsertGroup = upsertGroup
        self.upsertTag = upsertTag
    }

    func execute(_ url: URL,
                 onPlacesCountResolved: ((Int) -> Void),
                 completion: ((Int) -> Void)) async throws {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let export = try decode(data)
        Log.info("Found \(export.places.count) places, \(export.tags.count) tags, \(export.groups.count) groups")
        onPlacesCountResolved(export.places.count)
        try await persist(export)
        Log.info(" -> persisted")
        completion(export.places.count)
    }

    // MARK: - Private
    private func decode(_ data: Data) throws -> DropinInOut {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let export = try decoder.decode(DropinInOut.self, from: data)

        switch export.version {
            case 1:
                return export
            default:
                throw ImportError.versionTooNew(export.version)
        }
    }

    private func persist(_ export: DropinInOut) async throws {
        // Upsert groups and tags first (places depend on them)
        for group in export.groups {
            try await upsertGroup(group)
        }
        for tag in export.tags {
            try await upsertTag(tag)
        }
        // Upsert places
        for place in export.places {
            try await upsertPlace(place)
        }
    }
}
