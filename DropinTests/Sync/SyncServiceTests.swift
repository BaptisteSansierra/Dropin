//
//  SyncServiceTests.swift
//  DropinTests

import Testing
import Foundation
import CoreLocation
@testable import Dropin

@MainActor
struct SyncServiceTests {

    // MARK: - helpers

    private func makeSUT(localPlaceRepo: MockPlaceRepository = MockPlaceRepository(),
                         localCategoryRepo: MockCategoryRepository = MockCategoryRepository(),
                         localTagRepo: MockTagRepository = MockTagRepository(),
                         localImageRepo: MockImageRepository = MockImageRepository(),
                         localProfileRepo: MockProfileRepository = MockProfileRepository(),
                         remotePlaceRepo: MockRemotePlaceRepository = MockRemotePlaceRepository(),
                         remoteCategoryRepo: MockRemoteCategoryRepository = MockRemoteCategoryRepository(),
                         remoteTagRepo: MockRemoteTagRepository = MockRemoteTagRepository(),
                         remoteImageRepo: MockRemoteImageRepository = MockRemoteImageRepository(),
                         remoteProfileRepo: MockRemoteProfileRepository = MockRemoteProfileRepository(),
                         isOnline: Bool = true) -> SyncService {
        let freshDefaults = UserDefaults(suiteName: UUID().uuidString)!
        return SyncService(localPlaceRepo: localPlaceRepo,
                           localCategoryRepo: localCategoryRepo,
                           localTagRepo: localTagRepo,
                           localImageRepo: localImageRepo,
                           localProfileRepo: localProfileRepo,
                           remotePlaceRepo: remotePlaceRepo,
                           remoteCategoryRepo: remoteCategoryRepo,
                           remoteTagRepo: remoteTagRepo,
                           remoteImageRepo: remoteImageRepo,
                           remoteProfileRepo: remoteProfileRepo,
                           reachability: MockReachabilityService(isConnected: isOnline),
                           userDefaults: freshDefaults)
    }

    // MARK: - push

    @Test func syncAllPushesDirtyPlace() async throws {
        let place = Place(id: UUID(), name: "Test Place", coordinates: .london, address: "")
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository()
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        sut.markPlaceDirty(place.id)
        await sut.syncAll()

        #expect(remoteRepo.upsertedPlaces.map(\.id).contains(place.id))
    }

    @Test func syncAllPushesDirtyCategory() async throws {
        let category = Dropin.Category(name: "Test Group", color: "FF0000", icon: .sf("tag"))
        let localRepo = MockCategoryRepository(initialCategories: [category])
        let remoteRepo = MockRemoteCategoryRepository()
        let sut = makeSUT(localCategoryRepo: localRepo, remoteCategoryRepo: remoteRepo)

        sut.markCategoryDirty(category.id)
        await sut.syncAll()

        #expect(remoteRepo.upsertedCategories.map(\.id).contains(category.id))
    }

    @Test func syncAllPushesDirtyTag() async throws {
        let tag = Dropin.Tag(name: "Test Dropin.Tag", color: "0000FF")
        let localRepo = MockTagRepository(initialTags: [tag])
        let remoteRepo = MockRemoteTagRepository()
        let sut = makeSUT(localTagRepo: localRepo, remoteTagRepo: remoteRepo)

        sut.markTagDirty(tag.id)
        await sut.syncAll()

        #expect(remoteRepo.upsertedTags.map(\.id).contains(tag.id))
    }

    @Test func syncAllOfflineDoesNotPush() async throws {
        let place = Place(id: UUID(), name: "Test Place", coordinates: .london, address: "")
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository()
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo, isOnline: false)

        sut.markPlaceDirty(place.id)
        await sut.syncAll()

        #expect(remoteRepo.upsertedPlaces.isEmpty)
    }

    @Test func pushFailureKeepsItemInDirtySet() async throws {
        let place = Place(id: UUID(), name: "Test Place", coordinates: .london, address: "")
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository()
        remoteRepo.shouldThrowOnUpsert = true
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        sut.markPlaceDirty(place.id)
        await sut.syncAll()

        // Push failed → remote should be empty; marking dirty again and succeeding should push
        #expect(remoteRepo.upsertedPlaces.isEmpty)
        remoteRepo.shouldThrowOnUpsert = false
        await sut.syncAll()
        #expect(remoteRepo.upsertedPlaces.map(\.id).contains(place.id))
    }

    // MARK: - pull

    @Test func syncAllPullsRemoteChangesToLocal() async throws {
        let remotePlace = Place(id: UUID(), name: "Remote Place", coordinates: .london, address: "London")
        let localRepo = MockPlaceRepository()
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [remotePlace])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        await sut.syncAll()

        let fetched = try await localRepo.fetch(remotePlace.id)
        #expect(fetched.name == remotePlace.name)
    }

    @Test func syncAllPullPropagatesTombstone() async throws {
        let place = Place(id: UUID(), name: "To Delete", coordinates: .london, address: "")
        let tombstone = Place(id: place.id,
                                    name: place.name,
                                    coordinates: place.coordinates,
                                    address: place.address,
                                    deletedAt: Date())
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [tombstone])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        await sut.syncAll()

        let fetched = try await localRepo.fetch(place.id)
        #expect(fetched.deletedAt != nil)
    }

    @Test func syncAllPullIsIdempotent() async throws {
        let remotePlace = Place(id: UUID(), name: "Place", coordinates: .london, address: "")
        let localRepo = MockPlaceRepository()
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [remotePlace])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        await sut.syncAll()
        await sut.syncAll()

        let all = try await localRepo.fetch()
        #expect(all.filter { $0.id == remotePlace.id }.count == 1)
    }

    // MARK: - state

    @Test func syncAllUpdatesLastSyncedAt() async throws {
        let before = Date()
        let sut = makeSUT()

        await sut.syncAll()

        #expect(sut.syncStatus.lastSyncedAt != nil)
        #expect(sut.syncStatus.lastSyncedAt! >= before)
    }

    @Test func syncAllOfflineDoesNotUpdateLastSyncedAt() async throws {
        let sut = makeSUT(isOnline: false)

        await sut.syncAll()

        #expect(sut.syncStatus.lastSyncedAt == nil)
    }
}
