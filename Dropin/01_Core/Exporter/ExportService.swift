//
//  ExportService.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

@MainActor
struct ExportService {

    private var fetchPlaces: FetchPlaces
    private var getGroups: FetchGroups
    private var getTags: FetchTags
    
    init(fetchPlaces: FetchPlaces, getGroups: FetchGroups, getTags: FetchTags) {
        self.fetchPlaces = fetchPlaces
        self.getGroups = getGroups
        self.getTags = getTags
    }
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func execute() async throws {
        async let placesTask = fetchPlaces.execute()
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
        Log.info("Exported to \"\(url.absoluteString)\"")
    }
    
    private func encode(_ export: DropinExport) throws -> Data {
        try encoder.encode(export)
    }
    
    private func exportURL(for export: DropinExport) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formatedDate = formatter.string(from: export.exportedAt)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropin-export-\(formatedDate)")
            .appendingPathExtension("json")
        return url
    }
}
