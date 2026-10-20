//
//  Domain_ImportProvenance.swift
//  DropinTests
//
//  Covers withImportProvenance(importedAt:importSrc:) on Place/Category/Tag, and that the
//  .dropin export format never carries importedAt/importSrc (see App_ImportDropin/App_ImportMapstr
//  for the importer-side stamping behavior).
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

@MainActor
struct Domain_ImportProvenance {

    // MARK: - withImportProvenance

    @Test func placeWithImportProvenanceOnlyChangesTheTwoFields() async throws {
        let place = Place(id: UUID(), name: "Place", coordinates: .barcelona, address: "addr",
                          tags: [Dropin.Tag(name: "t", color: "FF0000")],
                          category: Dropin.Category(name: "c", color: "FF0000", icon: .sf("tag")),
                          icon: .sf("fork.knife"), notes: "notes")
        #expect(place.importedAt == nil)
        #expect(place.importSrc == nil)

        let date = Date()
        let stamped = place.withImportProvenance(importedAt: date, importSrc: .mapstr)

        #expect(stamped.importedAt == date)
        #expect(stamped.importSrc == .mapstr)
        // Everything else untouched
        #expect(stamped.id == place.id)
        #expect(stamped.name == place.name)
        #expect(stamped.coordinates.isIdentical(to: place.coordinates))
        #expect(stamped.address == place.address)
        #expect(stamped.tags.map(\.id) == place.tags.map(\.id))
        #expect(stamped.category?.id == place.category?.id)
        #expect(stamped.icon == place.icon)
        #expect(stamped.notes == place.notes)
        #expect(stamped.createdAt == place.createdAt)
        #expect(stamped.updatedAt == place.updatedAt)
        #expect(stamped.deletedAt == place.deletedAt)
    }

    @Test func categoryWithImportProvenanceOnlyChangesTheTwoFields() async throws {
        let category = Dropin.Category(name: "Restaurants", color: "FF5161", icon: .sf("fork.knife"))
        #expect(category.importedAt == nil)
        #expect(category.importSrc == nil)

        let date = Date()
        let stamped = category.withImportProvenance(importedAt: date, importSrc: .dropin)

        #expect(stamped.importedAt == date)
        #expect(stamped.importSrc == .dropin)
        #expect(stamped.id == category.id)
        #expect(stamped.name == category.name)
        #expect(stamped.color == category.color)
        #expect(stamped.icon == category.icon)
        #expect(stamped.createdAt == category.createdAt)
        #expect(stamped.updatedAt == category.updatedAt)
        #expect(stamped.deletedAt == category.deletedAt)
    }

    @Test func tagWithImportProvenanceOnlyChangesTheTwoFields() async throws {
        let tag = Dropin.Tag(name: "Vegan", color: "00FF00")
        #expect(tag.importedAt == nil)
        #expect(tag.importSrc == nil)

        let date = Date()
        let stamped = tag.withImportProvenance(importedAt: date, importSrc: .mapstr)

        #expect(stamped.importedAt == date)
        #expect(stamped.importSrc == .mapstr)
        #expect(stamped.id == tag.id)
        #expect(stamped.name == tag.name)
        #expect(stamped.color == tag.color)
        #expect(stamped.createdAt == tag.createdAt)
        #expect(stamped.updatedAt == tag.updatedAt)
        #expect(stamped.deletedAt == tag.deletedAt)
    }

    // MARK: - .dropin export never carries import provenance

    @Test func placeCodingOmitsProvenance() async throws {
        let place = Place(id: UUID(), name: "Place", coordinates: .barcelona, address: "addr",
                          tags: [], category: nil)
            .withImportProvenance(importedAt: Date(), importSrc: .mapstr)

        let data = try ExportService.encoder.encode(place)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["importedAt"] == nil)
        #expect(json?["importSrc"] == nil)
    }

    @Test func categoryCodingOmitsProvenance() async throws {
        let category = Dropin.Category(name: "Restaurants", color: "FF5161", icon: .sf("fork.knife"))
            .withImportProvenance(importedAt: Date(), importSrc: .dropin)

        let data = try ExportService.encoder.encode(category)
        // Check encode
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["importedAt"] == nil)
        #expect(json?["importSrc"] == nil)
        // Check decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Dropin.Category.self, from: data)
        #expect(decoded.importedAt == nil)
        #expect(decoded.importSrc == nil)
    }

    @Test func tagCodingOmitsProvenance() async throws {
        let tag = Dropin.Tag(name: "Vegan", color: "00FF00")
            .withImportProvenance(importedAt: Date(), importSrc: .mapstr)

        let data = try ExportService.encoder.encode(tag)
        // Check encode
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["importedAt"] == nil)
        #expect(json?["importSrc"] == nil)
        // Check decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Dropin.Tag.self, from: data)
        #expect(decoded.importedAt == nil)
        #expect(decoded.importSrc == nil)
    }
}
