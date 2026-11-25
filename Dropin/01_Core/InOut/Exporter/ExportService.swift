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
    private let fetchCategories: FetchCategories
    private let fetchTags: FetchTags
    
    init(fetchPlaces: FetchPlaces, fetchCategories: FetchCategories, fetchTags: FetchTags) {
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
    }
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func execute() async throws -> URL {
        async let placesTask = fetchPlaces()
            .filter { $0.isActive }
        async let groupsTask = fetchCategories()
            .filter { $0.isActive }
        async let tagsTask = fetchTags()
            .filter { $0.isActive }

        let (places, categories, tags) = try await (placesTask, groupsTask, tagsTask)

        let dropinExport = DropinInOut(exportedAt: Date(),
                                       places: places,
                                       categories: categories,
                                       tags: tags)
        let data = try encode(dropinExport)
        let url = exportURL(for: dropinExport)
        try data.write(to: url)
        Log.info("Exported to \"\(url.absoluteString)\"")
        return url
    }
    
    private func encode(_ export: DropinInOut) throws -> Data {
        try Self.encoder.encode(export)
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
