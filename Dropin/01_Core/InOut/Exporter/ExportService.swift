//
//  ExportService.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

@MainActor
struct ExportService {

    private let fetchPlaces: FetchPlaces
    private let fetchGroups: FetchGroups
    private let fetchTags: FetchTags
    
    init(fetchPlaces: FetchPlaces, fetchGroups: FetchGroups, fetchTags: FetchTags) {
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
    }
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func execute() async throws -> URL {
        async let placesTask = fetchPlaces()
        async let groupsTask = fetchGroups()
        async let tagsTask = fetchTags()
        
        let (places, groups, tags) = try await (placesTask, groupsTask, tagsTask)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                        places: places,
                                        groups: groups,
                                        tags: tags)
        let data = try encode(dropinExport)
        let url = exportURL(for: dropinExport)
        try data.write(to: url)
        Log.info("Exported to \"\(url.absoluteString)\"")
        return url
    }
    
    private func encode(_ export: DropinInOut) throws -> Data {
        try encoder.encode(export)
    }
    
    private func exportURL(for export: DropinInOut) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formatedDate = formatter.string(from: export.exportedAt)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropin-export-\(formatedDate)")
            .appendingPathExtension(DropinApp.strings.exportExtension)
        return url
    }
}
