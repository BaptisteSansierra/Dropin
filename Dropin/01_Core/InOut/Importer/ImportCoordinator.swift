//
//  ImportSource.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
final class ImportCoordinator {

    private let source: ImportSource
    private let url: URL
    private let importService: ImportServiceProtocol

    init(source: ImportSource,
         url: URL,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag,
         markerTagName: String? = nil) throws {
        self.source = source
        self.url = url
        switch source {
            case .dropin:
                importService = ImportDropinService(upsertPlace: upsertPlace,
                                                    upsertGroup: upsertGroup,
                                                    upsertTag: upsertTag)
            case .mapstr:
                importService = ImportMapstrService(upsertPlace: upsertPlace,
                                                    upsertTag: upsertTag,
                                                    markerTagName: markerTagName ?? "Mapstr")
            default:
                throw ImportError.unrecognizedFormat(url.pathExtension)
        }
        try checkFile()
    }
    
    func process() async throws {
        try await importService.execute(url)
    }

    // MARK: - Private
    private func checkFile() throws {
        let ext = url.pathExtension.lowercased()
        switch source {
            case .dropin:
                guard ext == DropinApp.strings.exportExtension else {
                    throw ImportError.unrecognizedFormat(ext)
                }
            case .mapstr, .google:
                guard ext == "geojson" else {
                    throw ImportError.unrecognizedFormat(ext)
                }
            default:
                ()
        }
    }
}


