//
//  Domain_EntityNames.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/11/26.
//

import Foundation
import Testing
@testable import Dropin

/// Entity names rules applied by the Create / Update / Upsert use cases:
///  - stored without surrounding whitespaces
///  - whitespaces only is a missing name
///  - tags and categories: no two active ones share a name (case-insensitive, surrounding whitespaces ignored)
@MainActor
struct Domain_EntityNames {

    private let color = "#ff5161"
    private let icon = Icon.sf("tag")

    // MARK: - Helpers
    private func tag(_ name: String) -> Dropin.Tag {
        Dropin.Tag(name: name, color: color)
    }

    private func category(_ name: String) -> Dropin.Category {
        Dropin.Category(name: name, color: color, icon: icon)
    }

    private func place(_ name: String) -> Place {
        Place(id: UUID(), name: name, coordinates: .barcelona, address: "")
    }

    private func renamed(_ tag: Dropin.Tag, _ name: String) -> Dropin.Tag {
        Dropin.Tag(id: tag.id, name: name, color: tag.color,
                   createdAt: tag.createdAt, updatedAt: tag.updatedAt, deletedAt: tag.deletedAt)
    }

    private func renamed(_ category: Dropin.Category, _ name: String) -> Dropin.Category {
        Dropin.Category(id: category.id, name: name, color: category.color, icon: category.icon,
                        createdAt: category.createdAt, updatedAt: category.updatedAt, deletedAt: category.deletedAt)
    }

    private func renamed(_ place: Place, _ name: String) -> Place {
        Place(id: place.id, name: name, coordinates: place.coordinates, address: place.address,
              address2: place.address2, tags: place.tags, category: place.category, icon: place.icon,
              rating: place.rating, phone: place.phone, email: place.email, url: place.url, notes: place.notes,
              createdAt: place.createdAt, updatedAt: place.updatedAt, deletedAt: place.deletedAt)
    }

    // MARK: - String

    @Test func trimmedNameAndNameKey() {
        #expect("  Mapstr \n".trimmedName == "Mapstr")
        #expect("Mapstr  import".trimmedName == "Mapstr  import")     // Inner whitespaces are kept
        #expect("  MAPSTR ".nameKey == "mapstr")
        #expect("Mapstr".nameKey == " mapstr ".nameKey)
    }

    // MARK: - Tag

    @Test func createTagTrimsName() async throws {
        let repo = MockTagRepository()
        let tag = tag("  Rooftop ")
        try await CreateTag(repository: repo)(tag)
        #expect(try await repo.fetch(tag.id).name == "Rooftop")
    }

    @Test func createTagKeepsCleanName() async throws {
        let repo = MockTagRepository()
        let tag = tag("Rooftop")
        try await CreateTag(repository: repo)(tag)
        #expect(try await repo.fetch(tag.id).name == "Rooftop")
    }

    @Test func createTagRejectsWhitespacesOnlyName() async throws {
        let repo = MockTagRepository()
        await #expect(throws: DomainError.Tag.missingName) {
            try await CreateTag(repository: repo)(tag("   "))
        }
    }

    @Test func createTagRejectsDuplicateName() async throws {
        let repo = MockTagRepository(initialTags: [tag("Rooftop")])
        await #expect(throws: DomainError.Tag.nameAlreadyExists) {
            try await CreateTag(repository: repo)(tag(" rooftop  "))
        }
    }

    @Test func createTagIgnoresSoftDeletedName() async throws {
        let repo = MockTagRepository(initialTags: [tag("Rooftop").deleted(deletedAt: Date())])
        try await CreateTag(repository: repo)(tag("Rooftop"))
        #expect(try await repo.fetch().filter { $0.isActive }.count == 1)
    }

    @Test func updateTagTrimsName() async throws {
        let original = tag("Rooftop")
        let repo = MockTagRepository(initialTags: [original])
        try await UpdateTag(repository: repo)(renamed(original, "  Terrace "))
        #expect(try await repo.fetch(original.id).name == "Terrace")
    }

    @Test func updateTagRejectsWhitespacesOnlyName() async throws {
        let original = tag("Rooftop")
        let repo = MockTagRepository(initialTags: [original])
        await #expect(throws: DomainError.Tag.missingName) {
            try await UpdateTag(repository: repo)(renamed(original, "  "))
        }
    }

    @Test func updateTagRejectsDuplicateName() async throws {
        let original = tag("Rooftop")
        let repo = MockTagRepository(initialTags: [original, tag("Terrace")])
        await #expect(throws: DomainError.Tag.nameAlreadyExists) {
            try await UpdateTag(repository: repo)(renamed(original, "TERRACE "))
        }
    }

    @Test func updateTagAllowsItsOwnNameWithAnotherCase() async throws {
        let original = tag("Rooftop")
        let repo = MockTagRepository(initialTags: [original])
        try await UpdateTag(repository: repo)(renamed(original, "rooftop"))
        #expect(try await repo.fetch(original.id).name == "rooftop")
    }

    @Test func updateTagIgnoresSoftDeletedName() async throws {
        let original = tag("Rooftop")
        let repo = MockTagRepository(initialTags: [original, tag("Terrace").deleted(deletedAt: Date())])
        try await UpdateTag(repository: repo)(renamed(original, "Terrace"))
        #expect(try await repo.fetch(original.id).name == "Terrace")
    }

    @Test func upsertTagTrimsName() async throws {
        let repo = MockTagRepository()
        let tag = tag(" Rooftop ")
        try await UpsertTag(repository: repo)(tag)
        #expect(try await repo.fetch(tag.id).name == "Rooftop")
    }

    @Test func upsertTagRejectsWhitespacesOnlyName() async throws {
        let repo = MockTagRepository()
        await #expect(throws: DomainError.Tag.missingName) {
            try await UpsertTag(repository: repo)(tag(" "))
        }
    }

    // MARK: - Category

    @Test func createCategoryTrimsName() async throws {
        let repo = MockCategoryRepository()
        let category = category("  Restaurant ")
        try await CreateCategory(repository: repo)(category)
        #expect(try await repo.fetch(category.id).name == "Restaurant")
    }

    @Test func createCategoryRejectsWhitespacesOnlyName() async throws {
        let repo = MockCategoryRepository()
        await #expect(throws: DomainError.Category.missingName) {
            try await CreateCategory(repository: repo)(category("   "))
        }
    }

    @Test func createCategoryRejectsDuplicateName() async throws {
        let repo = MockCategoryRepository(initialCategories: [category("Restaurant")])
        await #expect(throws: DomainError.Category.nameAlreadyExists) {
            try await CreateCategory(repository: repo)(category(" restaurant "))
        }
    }

    @Test func createCategoryIgnoresSoftDeletedName() async throws {
        let repo = MockCategoryRepository(initialCategories: [category("Restaurant").deleted(deletedAt: Date())])
        try await CreateCategory(repository: repo)(category("Restaurant"))
        #expect(try await repo.fetch().filter { $0.isActive }.count == 1)
    }

    @Test func updateCategoryTrimsName() async throws {
        let original = category("Restaurant")
        let repo = MockCategoryRepository(initialCategories: [original])
        try await UpdateCategory(repository: repo)(renamed(original, " Bar  "))
        #expect(try await repo.fetch(original.id).name == "Bar")
    }

    @Test func updateCategoryRejectsWhitespacesOnlyName() async throws {
        let original = category("Restaurant")
        let repo = MockCategoryRepository(initialCategories: [original])
        await #expect(throws: DomainError.Category.missingName) {
            try await UpdateCategory(repository: repo)(renamed(original, " "))
        }
    }

    @Test func updateCategoryRejectsDuplicateName() async throws {
        let original = category("Restaurant")
        let repo = MockCategoryRepository(initialCategories: [original, category("Bar")])
        await #expect(throws: DomainError.Category.nameAlreadyExists) {
            try await UpdateCategory(repository: repo)(renamed(original, "bar "))
        }
    }

    @Test func updateCategoryAllowsItsOwnNameWithAnotherCase() async throws {
        let original = category("Restaurant")
        let repo = MockCategoryRepository(initialCategories: [original])
        try await UpdateCategory(repository: repo)(renamed(original, "RESTAURANT"))
        #expect(try await repo.fetch(original.id).name == "RESTAURANT")
    }

    @Test func upsertCategoryTrimsName() async throws {
        let repo = MockCategoryRepository()
        let category = category(" Restaurant ")
        try await UpsertCategory(repository: repo)(category)
        #expect(try await repo.fetch(category.id).name == "Restaurant")
    }

    // MARK: - Place (names may be shared)

    @Test func createPlaceTrimsName() async throws {
        let repo = MockPlaceRepository()
        let place = place("  Blue Bistro ")
        try await CreatePlace(repository: repo)(place)
        #expect(try await repo.fetch(place.id).name == "Blue Bistro")
    }

    @Test func createPlaceRejectsWhitespacesOnlyName() async throws {
        let repo = MockPlaceRepository()
        await #expect(throws: DomainError.Place.missingName) {
            try await CreatePlace(repository: repo)(place("  \n"))
        }
    }

    @Test func createPlaceAllowsDuplicateName() async throws {
        let repo = MockPlaceRepository(initialPlaces: [place("Starbucks")])
        try await CreatePlace(repository: repo)(place("Starbucks"))
        #expect(try await repo.fetch().count == 2)
    }

    @Test func updatePlaceTrimsName() async throws {
        let original = place("Blue Bistro")
        let repo = MockPlaceRepository(initialPlaces: [original])
        try await UpdatePlace(repository: repo)(renamed(original, " Red Bistro "))
        #expect(try await repo.fetch(original.id).name == "Red Bistro")
    }

    @Test func updatePlaceRejectsWhitespacesOnlyName() async throws {
        let original = place("Blue Bistro")
        let repo = MockPlaceRepository(initialPlaces: [original])
        await #expect(throws: DomainError.Place.missingName) {
            try await UpdatePlace(repository: repo)(renamed(original, "   "))
        }
    }

    @Test func upsertPlaceTrimsName() async throws {
        let repo = MockPlaceRepository()
        let place = place(" Blue Bistro ")
        try await UpsertPlace(repository: repo)(place)
        #expect(try await repo.fetch(place.id).name == "Blue Bistro")
    }
}
