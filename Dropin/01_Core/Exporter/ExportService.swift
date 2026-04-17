//
//  ExportService.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

@MainActor
struct ExportService {

    private var getPlaces: GetPlaces
    private var getGroups: GetGroups
    private var getTags: GetTags
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func execute() async throws {
        async let placesTask = getPlaces.execute()
        async let groupsTask = getGroups.execute()
        async let tagsTask = getTags.execute()
        
        let (places, groups, tags) = try await (placesTask, groupsTask, tagsTask)

        let dropinExport = DropinExport(exportedAt: Date(),
                                        places: places,
                                        groups: groups,
                                        tags: tags)
        let data = try encode(dropinExport)
        let url = exportURL(for: dropinExport)
        try data.write(to: url)
    }
    
    private func encode(_ export: DropinExport) throws -> Data {
        try encoder.encode(export)
    }
    
    private func exportURL(for export: DropinExport) -> URL {
        let formatedDate = ISO8601DateFormatter().string(from: export.exportedAt)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropin-export-\(formatedDate)")
            .appendingPathExtension("json")
        return url
    }
}
