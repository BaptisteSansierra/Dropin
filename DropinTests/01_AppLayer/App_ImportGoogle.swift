//
//  App_ImportGoogle.swift
//  DropinTests
//
//  Created by baptiste sansierra on 24/11/26.
//

import Foundation
import CoreLocation
import Testing
import ContactFieldKit
@testable import Dropin

private class BundleFinder {}

@MainActor
struct App_ImportGoogle {

    /// "Saved Places.json": 7 features, 6 places
    ///     "Platja Del Torn" has no location, null coordinates and an url without coordinates: skipped
    private let savedPlacesFile = "Saved Places"
    /// "Reviews.json": 10 features, 10 places, all rated, 8 with a review
    private let reviewsFile = "Reviews"
    /// In both files
    private let pipoteName = "pizzeria pipote"
    private let pipoteCoords = CLLocationCoordinate2D(latitude: 44.7049301, longitude: 7.839932)

    private var emptyDataStr =
    """
        {
          "type": "FeatureCollection",
          "features": []
        }
    """

    private let localGeneralRepo: MockGeneralRepository = MockGeneralRepository()
    private let localPlaceRepo: MockPlaceRepository = MockPlaceRepository()
    private let localCategoryRepo: MockCategoryRepository = MockCategoryRepository()
    private let localTagRepo: MockTagRepository = MockTagRepository()

    private func importService() -> ImportGoogleService {
        ImportGoogleService(saveContext: SaveContext(repository: localGeneralRepo),
                            rollbackContext: RollbackContext(repository: localGeneralRepo),
                            fetchPlaces: FetchPlaces(repository: localPlaceRepo),
                            fetchCategories: FetchCategories(repository: localCategoryRepo),
                            fetchTags: FetchTags(repository: localTagRepo),
                            upsertPlace: UpsertPlace(repository: localPlaceRepo),
                            upsertCategory: UpsertCategory(repository: localCategoryRepo),
                            upsertTag: UpsertTag(repository: localTagRepo))
    }

    private func fileData(_ name: String) throws -> Data {
        let bundle = Bundle(for: BundleFinder.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json"),
                               "\(name).json not found in test bundle")
        return try Data(contentsOf: url)
    }

    /// A single feature file
    private func featureData(coordinates: String, properties: String) -> Data {
        Data("""
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": { "type": "Point", "coordinates": \(coordinates) },
              "properties": \(properties)
            }
          ]
        }
        """.utf8)
    }

    /// Runs phase 2 with no import tag, returns the counters (created, duplicates, categories, tags)
    @discardableResult
    private func runImport(_ service: ImportGoogleService,
                           _ plan: GoogleImportPlan,
                           tagImport: Bool = false,
                           tagName: String = "") async throws -> (Int, Int, Int, Int) {
        var counters = (0, 0, 0, 0)
        try await service.import(plan, tagImport: tagImport, tagName: tagName) { _ in
        } canceled: {
        } completion: { created, duplicates, categories, tags in
            counters = (created, duplicates, categories, tags)
        }
        return counters
    }

    // MARK: - Phase 1: read

    ///
    /// Test reading "Saved Places.json":
    ///     places with a location are read, the one without location nor coordinates is skipped
    ///
    @Test func readSavedPlaces() async throws {
        let plan = try await importService().read(try fileData(savedPlacesFile))
        #expect(plan.places.count == 6)
        #expect(!plan.places.contains { $0.url.contains("Platja+Del+Torn") })

        let pipote = try #require(plan.places.first { $0.name == pipoteName })
        // GeoJSON coordinates are [longitude, latitude]
        #expect(pipote.coordinates.latitude == pipoteCoords.latitude)
        #expect(pipote.coordinates.longitude == pipoteCoords.longitude)
        #expect(pipote.address == "Via Senatore Giovanni Sartori, 29, 12042 Bra CN, Italy")
        #expect(pipote.url == "http://maps.google.com/?cid=14627781221597758247")
        // Saved places have no review
        #expect(plan.places.allSatisfy { $0.rating == nil && $0.review == nil })
    }

    ///
    /// Test reading "Reviews.json":
    ///     every place is read with its rating, the review is optional, unknown keys ("questions") are ignored
    ///
    @Test func readReviews() async throws {
        let plan = try await importService().read(try fileData(reviewsFile))
        #expect(plan.places.count == 10)
        #expect(plan.places.allSatisfy { $0.rating != nil })
        #expect(plan.places.filter { $0.review != nil }.count == 8)

        let pipote = try #require(plan.places.first { $0.name == pipoteName })
        #expect(pipote.rating == 5)
        #expect(pipote.review == "El burger es brutal")

        // Has a "questions" key
        let karamba = try #require(plan.places.first { $0.name == "Guingueta Karamba" })
        #expect(karamba.rating == 1)

        // No "review_text_published"
        let gestalt = try #require(plan.places.first { $0.name == "Ma Gestalt" })
        #expect(gestalt.rating == 5)
        #expect(gestalt.review == nil)
    }

    ///
    /// Test a place with null coordinates and coordinates in its url:
    ///     read as a dropped pin, at the url coordinates
    ///
    @Test func readDroppedPin() async throws {
        let url = "http://maps.google.com/?q=42.81687794930286,-1.6456934809684753"
        let data = featureData(coordinates: "[0, 0]", properties: """
            { "date": "2026-11-21T07:43:28Z", "google_maps_url": "\(url)",
              "Comment": "No location information is available for this saved place" }
            """)
        let plan = try await importService().read(data)
        #expect(plan.places.count == 1)
        let pin = try #require(plan.places.first)
        #expect(pin.name == String(localized: LocalizedStringResource("common.from_google_maps.unnamed")))
        #expect(pin.coordinates.latitude == 42.81687794930286)
        #expect(pin.coordinates.longitude == -1.6456934809684753)
        #expect(pin.address == nil)
        #expect(pin.url == url)
    }

    ///
    /// Test a place with null coordinates and an url without coordinates: skipped, not an error
    ///
    @Test func readSkipsUnlocatedPlace() async throws {
        let data = featureData(coordinates: "[0, 0]", properties: """
            { "date": "2026-11-21T07:43:28Z", "google_maps_url": "http://maps.google.com/?q=Platja+Del+Torn,+43890" }
            """)
        let plan = try await importService().read(data)
        #expect(plan.places.isEmpty)
    }

    ///
    /// Test ImportGoogleService empty file
    ///  check error when file is empty, at phase 1 (read)
    ///
    @Test func readEmpty() async throws {
        await #expect(throws: ImportError.emptyFile) {
            _ = try await importService().read(Data(emptyDataStr.utf8))
        }
    }

    ///
    /// Test ImportGoogleService corrupted file
    ///  check error when file is corrupted, at phase 1 (read)
    ///
    @Test func readCorrupted() async throws {
        await #expect(throws: ImportError.decoding("no_matter")) {
            _ = try await importService().read(Data("cOrRuptEd".utf8))
        }
    }

    ///
    /// Test a feature missing a required property ("google_maps_url"): the whole file is rejected
    ///
    @Test func readMissingRequiredProperty() async throws {
        let data = featureData(coordinates: "[7.839932, 44.7049301]", properties: """
            { "date": "2026-11-23T09:30:43Z",
              "location": { "name": "pizzeria pipote", "address": "Bra, Italy" } }
            """)
        await #expect(throws: ImportError.decoding("no_matter")) {
            _ = try await importService().read(data)
        }
    }

    // MARK: - Phase 2: import

    ///
    /// Test importing "Reviews.json": places are created with their rating, review (notes),
    /// google url, import source, and no tag nor category
    ///
    @Test func importReviews() async throws {
        let service = importService()
        let plan = try await service.read(try fileData(reviewsFile))

        var counter = 0
        try await service.import(plan, tagImport: false, tagName: "") { count in
            #expect(count == counter + 1)    // Check progress counter
            counter += 1
        } canceled: {
        } completion: { createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount in
            #expect(createdPlacesCount == 10)
            #expect(duplicatePlacesCount == 0)
            #expect(createdCategoriesCount == 0)
            #expect(createdTagsCount == 0)
        }
        #expect(counter == 10)

        let places = try await localPlaceRepo.fetch()
        #expect(places.count == 10)
        #expect(try await localTagRepo.fetch().isEmpty)
        #expect(try await localCategoryRepo.fetch().isEmpty)

        let pipote = try #require(places.first { $0.name == pipoteName })
        #expect(pipote.rating == 5)
        #expect(pipote.notes == "El burger es brutal")
        #expect(pipote.address == "Via Senatore Giovanni Sartori, 29, 12042 Bra CN, Italy")
        #expect(pipote.tags.isEmpty)
        #expect(pipote.category == nil)
        #expect(pipote.phone.isEmpty)
        #expect(pipote.email.isEmpty)

        // The google url is stored as an url field, with a custom label
        #expect(pipote.url.count == 1)
        let url = try #require(pipote.url.first.flatMap(ContactItem.init(rawValue:)))
        #expect(url.value == "https://www.google.com/maps/place//data=!4m2!3m1!1s0x0:0xcb0051850d76c327")
        #expect(url.label == .url(.custom(String(localized: "common.from_google_maps"))))

        // Check import source, all places share the same import date
        #expect(places.allSatisfy { $0.importSrc == .google })
        let importedAt = try #require(pipote.importedAt)
        #expect(places.allSatisfy { $0.importedAt == importedAt })
        #expect(pipote.createdAt == importedAt)
        #expect(pipote.updatedAt == importedAt)
    }

    ///
    /// Test ImportGoogleService do not duplicate places:
    ///     importing "Reviews.json" after "Saved Places.json", pipote is a duplicate
    ///     the existing place is not updated with the review
    ///
    @Test func importPlacesDuplicates() async throws {
        let service = importService()
        try await runImport(service, try await service.read(try fileData(savedPlacesFile)))

        let secondService = importService()
        let counters = try await runImport(secondService, try await secondService.read(try fileData(reviewsFile)))
        #expect(counters.0 == 9)    // created
        #expect(counters.1 == 1)    // duplicates

        let places = try await localPlaceRepo.fetch()
        #expect(places.count == 15)
        let pipotes = places.filter { $0.name == pipoteName }
        #expect(pipotes.count == 1)
        #expect(pipotes.first?.rating == nil)
        #expect(pipotes.first?.notes == nil)
    }

    ///
    /// Test ImportGoogleService duplicates soft deleted places
    ///
    @Test func importPlacesDuplicatesDeleted() async throws {
        var pipoteLocal = Place(id: UUID(), name: pipoteName, coordinates: pipoteCoords, address: "nop")
        pipoteLocal = pipoteLocal.deleted(deletedAt: Date())
        try await UpsertPlace(repository: localPlaceRepo)(pipoteLocal)

        let service = importService()
        let counters = try await runImport(service, try await service.read(try fileData(savedPlacesFile)))
        #expect(counters.0 == 6)    // created
        #expect(counters.1 == 0)    // duplicates

        let places = try await localPlaceRepo.fetch()
        #expect(places.count == 7)
        #expect(places.filter { $0.name == pipoteName }.count == 2)
    }

    ///
    /// Test ImportGoogleService with tagImport on:
    ///  a single import tag is created and added to every imported place, duplicates (not imported) stay untouched
    ///
    @Test func importTagImportOn() async throws {
        let tagName = "Google Maps import"
        // pipote is a duplicate, it won't be imported
        let pipoteLocal = Place(id: UUID(), name: pipoteName, coordinates: pipoteCoords, address: "nop")
        try await UpsertPlace(repository: localPlaceRepo)(pipoteLocal)

        let service = importService()
        let counters = try await runImport(service, try await service.read(try fileData(savedPlacesFile)),
                                           tagImport: true, tagName: tagName)
        #expect(counters.0 == 5)    // created
        #expect(counters.1 == 1)    // duplicates
        #expect(counters.3 == 1)    // tags

        let tags = try await localTagRepo.fetch()
        #expect(tags.count == 1)
        let importTag = try #require(tags.first)
        #expect(importTag.name == tagName)
        #expect(importTag.importSrc == .google)

        let places = try await localPlaceRepo.fetch()
        let imported = places.filter { $0.id != pipoteLocal.id }
        #expect(imported.count == 5)
        #expect(imported.allSatisfy { $0.tags.map(\.id) == [importTag.id] })
        #expect(importTag.importedAt == imported.first?.importedAt)
        // Check the local duplicate didn't get it
        let local = try #require(places.first { $0.id == pipoteLocal.id })
        #expect(local.tags.isEmpty)
    }

    ///
    /// Test ImportGoogleService with tagImport on, the import tag named like an existing local tag:
    ///  the local tag is used, no second tag with that name
    ///
    @Test func importTagImportNameExists() async throws {
        let tagName = "Google Maps import"
        let localTag = Dropin.Tag(name: tagName, color: String.randomColor())
        try await UpsertTag(repository: localTagRepo)(localTag)

        let service = importService()
        let counters = try await runImport(service, try await service.read(try fileData(savedPlacesFile)),
                                           tagImport: true, tagName: tagName)
        #expect(counters.3 == 0)    // tags

        let tags = try await localTagRepo.fetch()
        #expect(tags.map(\.id) == [localTag.id])
        let places = try await localPlaceRepo.fetch()
        #expect(places.count == 6)
        #expect(places.allSatisfy { $0.tags.map(\.id) == [localTag.id] })
    }

    ///
    /// Test ImportGoogleService with tagImport on and a blank tag name: no tag is created
    ///
    @Test func importTagImportBlankName() async throws {
        let service = importService()
        let counters = try await runImport(service, try await service.read(try fileData(savedPlacesFile)),
                                           tagImport: true, tagName: "   ")
        #expect(counters.0 == 6)
        #expect(counters.3 == 0)
        #expect(try await localTagRepo.fetch().isEmpty)
    }
}
