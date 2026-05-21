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
    private let sync: any SyncServicePausableProtocol

    init(source: ImportSource,
         url: URL,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag,
         sync: any SyncServicePausableProtocol,
         markerTagName: String? = nil) throws {
        self.source = source
        self.url = url
        self.sync = sync
        switch source {
            case .dropin:
                Log.info("Dropin import service created")
                importService = ImportDropinService(upsertPlace: upsertPlace,
                                                    upsertGroup: upsertGroup,
                                                    upsertTag: upsertTag)
            case .mapstr:
                Log.info("Mapstr import service created")
                importService = ImportMapstrService(upsertPlace: upsertPlace,
                                                    upsertTag: upsertTag,
                                                    markerTagName: markerTagName ?? "Mapstr")
            default:
                Log.error("unrecognized file to be imported \(url.pathExtension)")
                throw ImportError.unrecognizedFormat(url.pathExtension)
        }
        try checkFile()
    }
    
    func process(onPlacesCountResolved: ((Int) -> Void),
                 completion: ((Int) -> Void)) async throws {
        // Pause remote pushes for the duration of the import so each upserted
        // tag/group/place doesn't trigger its own push. A single push runs at
        // the end with the full dirty set.
        try await sync.withPausedPushes {
            try await importService.execute(url,
                                            onPlacesCountResolved: onPlacesCountResolved,
                                            completion: completion)
        }
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


