//
//  Data_SpaceRepositoryImpl.swift
//  DropinTests
//
//  Covers the spaceId-scoping behavior added to PlaceRepositoryImpl/CategoryRepositoryImpl/
//  TagRepositoryImpl this session: every fetch is scoped to SpaceContext.currentSpaceId, an
//  upsert's insert branch stamps the right spaceId, and an upsert's update branch never
//  reassigns an existing record's space.
//

import Testing
import Foundation
import SwiftData
@testable import Dropin

@Suite(.serialized)
@MainActor
struct Data_SpaceRepositoryImpl {

    private struct Fixture {
        let modelContext: ModelContext
        /// The personal space is never a stored row — it's always `Space.mainId`.
        let secondarySpaceId: UUID
    }

    /// Shared across every test in this suite (one per process) rather than a fresh
    /// ModelContainer per test — creating many of these in quick succession in one process
    /// is unreliable in this SwiftData/simulator combo. Cleared and reseeded by makeFixture()
    /// before each test; @Suite(.serialized) keeps tests from racing on it.
    private static let sharedContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: PlaceRecord.self, TagRecord.self, CategoryRecord.self,
                                   PlaceImageRecord.self, ProfileRecord.self, SpaceRecord.self,
                                   configurations: config)
    }()

    private func makeFixture() throws -> Fixture {
        let context = Self.sharedContainer.mainContext
        context.autosaveEnabled = false
        try context.delete(model: PlaceRecord.self)
        try context.delete(model: CategoryRecord.self)
        try context.delete(model: TagRecord.self)
        try context.delete(model: SpaceRecord.self)
        try context.save()

        let secondarySpaceId = UUID()
        context.insert(SpaceRecord(identifier: secondarySpaceId, name: "Secondary", color: "8B5A2B", icon: .sf("briefcase"),
                                   ownerId: UUID()))
        return Fixture(modelContext: context, secondarySpaceId: secondarySpaceId)
    }

    private func makeSpaceContext() -> SpaceContext {
        SpaceContext(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    // MARK: - fetch scoping

    @Test func fetchOnlyReturnsCurrentSpacesPlaces() async throws {
        let fixture = try makeFixture()
        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)

        try await sut.create(Place(id: UUID(), name: "Main Place", coordinates: .barcelona, address: "", tags: []))
        fixture.modelContext.insert(PlaceRecord(identifier: UUID(), spaceId: fixture.secondarySpaceId,
                                                name: "Secondary Place", latitude: 0, longitude: 0))
        try fixture.modelContext.save()

        let visible = try await sut.fetch()
        #expect(visible.map(\.name) == ["Main Place"])
    }

    @Test func fetchByIdThrowsForAPlaceInAnotherSpace() async throws {
        let fixture = try makeFixture()
        let secondaryId = UUID()
        fixture.modelContext.insert(PlaceRecord(identifier: secondaryId, spaceId: fixture.secondarySpaceId,
                                                name: "Secondary Place", latitude: 0, longitude: 0))
        try fixture.modelContext.save()

        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)

        await #expect(throws: DataError.self) {
            _ = try await sut.fetch(secondaryId)
        }
    }

    @Test func fetchOnlyReturnsCurrentSpacesCategoriesAndTags() async throws {
        let fixture = try makeFixture()
        let spaceContext = makeSpaceContext()
        let categoryRepo = CategoryRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        let tagRepo = TagRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)

        try await categoryRepo.create(Dropin.Category(name: "Main Category", color: "9944AA", icon: .sf("tag")))
        try await tagRepo.create(Dropin.Tag(name: "Main Tag", color: "9944AA"))
        fixture.modelContext.insert(CategoryRecord(identifier: UUID(), spaceId: fixture.secondarySpaceId,
                                                   name: "Secondary Category", color: "000000", icon: .sf("tag")))
        fixture.modelContext.insert(TagRecord(identifier: UUID(), spaceId: fixture.secondarySpaceId,
                                              name: "Secondary Tag", color: "000000"))
        try fixture.modelContext.save()

        #expect(try await categoryRepo.fetch().map(\.name) == ["Main Category"])
        #expect(try await tagRepo.fetch().map(\.name) == ["Main Tag"])
    }

    // MARK: - insert stamps the right spaceId

    @Test func createStampsCurrentSpaceId() async throws {
        let fixture = try makeFixture()
        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        let place = Place(id: UUID(), name: "New Place", coordinates: .barcelona, address: "", tags: [])

        try await sut.create(place)

        let stored = try await sut.fetch(place.id)
        #expect(stored.spaceId == Space.mainId)
    }

    @Test func upsertInsertBranchUsesExplicitSpaceIdNotCurrentSpace() async throws {
        let fixture = try makeFixture()
        // Current space is Personal, but the explicit spaceId param (as SyncService.pull uses)
        // points at Secondary — the insert must land in Secondary, not Personal.
        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        let place = Place(id: UUID(), name: "Pulled Place", coordinates: .barcelona, address: "", tags: [])

        try await sut.upsert(place, spaceId: fixture.secondarySpaceId, shouldSave: true)

        // Not visible from the current (Personal) space...
        let visibleFromMain = try await sut.fetch()
        #expect(visibleFromMain.isEmpty)
        // ...but it exists, correctly stamped with Secondary's id.
        spaceContext.setCurrent(fixture.secondarySpaceId)
        let visibleFromSecondary = try await sut.fetch()
        #expect(visibleFromSecondary.map(\.spaceId) == [fixture.secondarySpaceId])
    }

    @Test func upsertUpdateBranchNeverReassignsSpace() async throws {
        let fixture = try makeFixture()
        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        let place = Place(id: UUID(), name: "Original", coordinates: .barcelona, address: "", tags: [])
        try await sut.create(place)

        // Even if the caller (or a stale domain object) carries a different spaceId, an
        // update to an EXISTING record must keep its own, original space.
        let edited = Place(id: place.id, name: "Renamed", coordinates: .barcelona, address: "", tags: [])
        try await sut.upsert(edited, spaceId: fixture.secondarySpaceId, shouldSave: true)

        let stored = try await sut.fetch(place.id)
        #expect(stored.name == "Renamed")
        #expect(stored.spaceId == Space.mainId)
    }

    // MARK: - cross-space linking is dropped, not crashed

    @Test func linkingATagFromAnotherSpaceIsSilentlyDropped() async throws {
        let fixture = try makeFixture()
        let foreignTagId = UUID()
        fixture.modelContext.insert(TagRecord(identifier: foreignTagId, spaceId: fixture.secondarySpaceId,
                                              name: "Foreign Tag", color: "000000"))
        try fixture.modelContext.save()

        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        let foreignTag = Dropin.Tag(id: foreignTagId, name: "Foreign Tag", color: "000000",
                                   createdAt: Date(), updatedAt: Date(), deletedAt: nil)
        let place = Place(id: UUID(), name: "Place", coordinates: .barcelona, address: "", tags: [foreignTag])

        try await sut.create(place)

        let stored = try await sut.fetch(place.id)
        #expect(stored.tags.isEmpty)
    }

    // MARK: - switching the shared SpaceContext

    @Test func switchingCurrentSpaceChangesWhatTheSameRepoInstanceReturns() async throws {
        let fixture = try makeFixture()
        let spaceContext = makeSpaceContext()
        let sut = PlaceRepositoryImpl(modelContext: fixture.modelContext, spaceContext: spaceContext)
        try await sut.create(Place(id: UUID(), name: "Main Place", coordinates: .barcelona, address: "", tags: []))

        #expect(try await sut.fetch().count == 1)

        spaceContext.setCurrent(fixture.secondarySpaceId)

        // Same repo instance, no reconstruction — it now sees Secondary's (empty) world.
        #expect(try await sut.fetch().isEmpty)
    }
}
