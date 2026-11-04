//
//  ImportSource.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

/// Phase-1 (read) output, wrapped per source since ImportServiceProtocol's
/// associated Plan type can't be stored as a single existential.
enum ImportPlan {
    case dropin(DropinInOut)
    case mapstr(MapstrImportPlan)
}

@MainActor
final class ImportCoordinator {

    private let source: ImportSource
    private let url: URL
    private let dropinService: ImportDropinService?
    private let mapstrService: ImportMapstrService?
    private let sync: any SyncServicePausableProtocol

    init(source: ImportSource,
         url: URL,
         saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertCategory: UpsertCategory,
         upsertTag: UpsertTag,
         sync: any SyncServicePausableProtocol) throws {
        self.source = source
        self.url = url
        self.sync = sync
        switch source {
            case .dropin:
                Log.info("Dropin import service created")
                dropinService = ImportDropinService(saveContext: saveContext,
                                                    rollbackContext: rollbackContext,
                                                    fetchPlaces: fetchPlaces,
                                                    fetchCategories: fetchCategories,
                                                    fetchTags: fetchTags,
                                                    upsertPlace: upsertPlace,
                                                    upsertCategory: upsertCategory,
                                                    upsertTag: upsertTag)
                mapstrService = nil
            case .mapstr:
                Log.info("Mapstr import service created")
                mapstrService = ImportMapstrService(saveContext: saveContext,
                                                    rollbackContext: rollbackContext,
                                                    fetchPlaces: fetchPlaces,
                                                    fetchCategories: fetchCategories,
                                                    fetchTags: fetchTags,
                                                    upsertPlace: upsertPlace,
                                                    upsertCategory: upsertCategory,
                                                    upsertTag: upsertTag)
                dropinService = nil
            default:
                Log.error("unrecognized file to be imported \(url.pathExtension)")
                throw ImportError.unsupported(url.pathExtension)
        }
        try checkFile()
    }

    // MARK: - Phase 1
    func readPlan() async throws -> ImportPlan {
        switch source {
            case .dropin:
                return .dropin(try await dropinService!.read(url))
            case .mapstr:
                return .mapstr(try await mapstrService!.read(url))
            default:
                throw ImportError.unsupported(url.pathExtension)
        }
    }

    // MARK: - Phase 2

    /// `mapping` is only meaningful for `.mapstr` plans; ignored otherwise.
    func importPlan(_ plan: ImportPlan,
                    mapping: CategoryMapping = [],
                    progress: @MainActor @Sendable (Int) -> Void,
                    canceled: @MainActor @Sendable () -> Void,
                    completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Pause remote pushes for the duration of the import so each upserted tag/category/place doesn't trigger
        // its own push. A single push runs at the end with the full dirty set.
        try await sync.withPausedPushes {
            switch plan {
                case .dropin(let export):
                    try await dropinService!.import(export, progress: progress, canceled: canceled, completion: completion)
                case .mapstr(let mapstrPlan):
                    try await mapstrService!.import(mapstrPlan, mapping: mapping, progress: progress, canceled: canceled, completion: completion)
            }
        }
    }

    // MARK: - Private
    private func checkFile() throws {
        let ext = url.pathExtension.lowercased()
        switch source {
            case .dropin:
                guard ext == DropinApp.strings.exportExtension else {
                    throw ImportError.unrecognizedFormat(.dropin, DropinApp.strings.exportExtension, ext)
                }
            case .mapstr:
                guard ext == "geojson" else {
                    throw ImportError.unrecognizedFormat(.mapstr, "geojson", ext)
                }
            default:
                ()
        }
    }
}
