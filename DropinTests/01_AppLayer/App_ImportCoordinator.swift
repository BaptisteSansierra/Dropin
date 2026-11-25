//
//  App_ImportCoordinator.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/11/26.
//

import Foundation
import Testing
@testable import Dropin

@MainActor
struct App_ImportCoordinator {

    private let localGeneralRepo = MockGeneralRepository()
    private let localPlaceRepo = MockPlaceRepository()
    private let localCategoryRepo = MockCategoryRepository()
    private let localTagRepo = MockTagRepository()

    private func importCoordinator(source: ImportSource, fileName: String) throws -> ImportCoordinator {
        try ImportCoordinator(source: source,
                              url: URL(fileURLWithPath: "/tmp/\(fileName)"),
                              tagImport: false,
                              tagName: "",
                              saveContext: SaveContext(repository: localGeneralRepo),
                              rollbackContext: RollbackContext(repository: localGeneralRepo),
                              fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                              fetchCategories: FetchCategories(repository: localCategoryRepo),
                              fetchTags: FetchTags(repository: localTagRepo),
                              upsertPlace: UpsertPlace(repository: localPlaceRepo),
                              upsertCategory: UpsertCategory(repository: localCategoryRepo),
                              upsertTag: UpsertTag(repository: localTagRepo),
                              sync: StubSyncService())
    }

    // MARK: - ImportCoordinator file check

    @Test func acceptsMatchingExtensions() throws {
        _ = try importCoordinator(source: .dropin, fileName: "export.dropin")
        _ = try importCoordinator(source: .mapstr, fileName: "export.geojson")
    }

    @Test func extensionIsCaseInsensitive() throws {
        _ = try importCoordinator(source: .dropin, fileName: "export.DROPIN")
        _ = try importCoordinator(source: .mapstr, fileName: "export.GeoJSON")
    }

    @Test func dropinRejectsOtherExtension() {
        expectUnrecognizedFormat(source: .dropin, fileName: "export.geojson", expected: "dropin", given: "geojson")
    }

    @Test func mapstrRejectsOtherExtension() {
        expectUnrecognizedFormat(source: .mapstr, fileName: "export.dropin", expected: "geojson", given: "dropin")
    }

    @Test func rejectsMissingExtension() {
        expectUnrecognizedFormat(source: .mapstr, fileName: "export", expected: "geojson", given: "")
    }

    @Test func rejectsUnknownSource() {
        let error = #expect(throws: ImportError.self) {
            _ = try importCoordinator(source: .unknown, fileName: "export.geojson")
        }
        // ImportError's == ignores associated values: check them explicitly
        guard case .unsupported(let ext) = error else {
            Issue.record("unexpected error \(String(describing: error))")
            return
        }
        #expect(ext == "geojson")
    }

    // MARK: - Helpers
    private func expectUnrecognizedFormat(source: ImportSource, fileName: String, expected: String, given: String,
                                          sourceLocation: SourceLocation = #_sourceLocation) {
        let error = #expect(throws: ImportError.self, sourceLocation: sourceLocation) {
            _ = try importCoordinator(source: source, fileName: fileName)
        }
        // ImportError's == ignores associated values: check them explicitly
        guard case .unrecognizedFormat(let errorSource, let errorExpected, let errorGiven) = error else {
            Issue.record("unexpected error \(String(describing: error))", sourceLocation: sourceLocation)
            return
        }
        #expect(errorSource == source, sourceLocation: sourceLocation)
        #expect(errorExpected == expected, sourceLocation: sourceLocation)
        #expect(errorGiven == given, sourceLocation: sourceLocation)
    }
}
