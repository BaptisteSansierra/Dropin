//
//  App_SyncService.swift
//  DropinTests

import Testing
import Foundation
import CoreLocation
@testable import Dropin

@MainActor
struct App_SyncService {

    // MARK: - helpers

    private func makeSUT(localPlaceRepo: MockPlaceRepository = MockPlaceRepository(),
                         localCategoryRepo: MockCategoryRepository = MockCategoryRepository(),
                         localTagRepo: MockTagRepository = MockTagRepository(),
                         localImageRepo: MockImageRepository = MockImageRepository(),
                         localProfileRepo: MockProfileRepository = MockProfileRepository(),
                         localSpaceRepo: MockSpaceRepository = MockSpaceRepository(),
                         remotePlaceRepo: MockRemotePlaceRepository = MockRemotePlaceRepository(),
                         remoteCategoryRepo: MockRemoteCategoryRepository = MockRemoteCategoryRepository(),
                         remoteTagRepo: MockRemoteTagRepository = MockRemoteTagRepository(),
                         remoteImageRepo: MockRemoteImageRepository = MockRemoteImageRepository(),
                         remoteProfileRepo: MockRemoteProfileRepository = MockRemoteProfileRepository(),
                         remoteSpaceRepo: MockRemoteSpaceRepository = MockRemoteSpaceRepository(),
                         isOnline: Bool = true,
                         reachability: MockReachabilityService? = nil) -> SyncService {
        let freshDefaults = UserDefaults(suiteName: UUID().uuidString)!
        return SyncService(localPlaceRepo: localPlaceRepo,
                           localCategoryRepo: localCategoryRepo,
                           localTagRepo: localTagRepo,
                           localImageRepo: localImageRepo,
                           localProfileRepo: localProfileRepo,
                           localSpaceRepo: localSpaceRepo,
                           remotePlaceRepo: remotePlaceRepo,
                           remoteCategoryRepo: remoteCategoryRepo,
                           remoteTagRepo: remoteTagRepo,
                           remoteImageRepo: remoteImageRepo,
                           remoteProfileRepo: remoteProfileRepo,
                           remoteSpaceRepo: remoteSpaceRepo,
                           reachability: reachability ?? MockReachabilityService(isConnected: isOnline),
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

    @Test func syncAllPushesDirtySpace() async throws {
        let space = Space(id: UUID(), name: "Secondary", color: "8B5A2B", icon: .sf("briefcase"),
                          ownerId: UUID(), createdAt: Date(), updatedAt: Date(), deletedAt: nil)
        let localRepo = MockSpaceRepository(initialSpaces: [space])
        let remoteRepo = MockRemoteSpaceRepository()
        let sut = makeSUT(localSpaceRepo: localRepo, remoteSpaceRepo: remoteRepo)

        sut.markSpaceDirty(space.id)
        await sut.syncAll()

        #expect(remoteRepo.upsertedSpaces.map(\.id).contains(space.id))
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
        let remotePlace = Place(id: UUID(), name: "Remote Place", coordinates: .london, address: "London", spaceId: UUID())
        let localRepo = MockPlaceRepository()
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [remotePlace])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        await sut.syncAll()

        let fetched = try await localRepo.fetch(remotePlace.id)
        #expect(fetched.name == remotePlace.name)
    }

    @Test func syncAllFirstPullIgnoreTombstone() async throws {
        let tombstone = Place(id: UUID(),
                              name: "To Delete",
                              coordinates: .london,
                              address: "",
                              spaceId: UUID())
            .deleted(deletedAt: Date())
        let localRepo = MockPlaceRepository(initialPlaces: [])
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [tombstone])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)
        await sut.syncAll()
        let fetched = try await localRepo.fetch()
        #expect(fetched.count == 0)
    }

    @Test func syncAllPullPropagatesTombstone() async throws {
        let place = Place(id: UUID(), name: "To Delete", coordinates: .london, address: "", spaceId: UUID())
        let tombstone = place.deleted(deletedAt: Date())
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository()
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        // Sync first so we ensure lastSyncedAt is defined
        await sut.syncAll()
        // Add the tmbstone on server side and sync again
        remoteRepo.placesToReturn = [tombstone]
        await sut.syncAll()

        let fetched = try await localRepo.fetch(place.id)
        #expect(fetched.deletedAt != nil)
    }

    @Test func syncAllPullsRemoteSpaceToLocal() async throws {
        let remoteSpace = Space(id: UUID(), name: "Secondary", color: "8B5A2B", icon: .sf("briefcase"),
                                ownerId: UUID(), createdAt: Date(), updatedAt: Date(), deletedAt: nil)
        let localRepo = MockSpaceRepository()
        let remoteRepo = MockRemoteSpaceRepository(spacesToReturn: [remoteSpace])
        let sut = makeSUT(localSpaceRepo: localRepo, remoteSpaceRepo: remoteRepo)

        await sut.syncAll()

        let fetched = try await localRepo.fetch(remoteSpace.id)
        #expect(fetched.name == remoteSpace.name)
    }

    // Regression: pull must route each entity to ITS OWN spaceId (as carried by the remote row),
    // never to whatever space happens to be active locally.
    // A user with multiple spaces could otherwise have a pull reassign an entity to the wrong space.
    // See: UpsertPlaceInSpace/UpsertCategoryInSpace/UpsertTagInSpace and PlaceRepositoryImpl.upsert.
    @Test func pullPlaceUsesItsOwnSpaceIdNotAnyLocalNotionOfCurrentSpace() async throws {
        let remoteSpaceId = UUID()
        let remotePlace = Place(id: UUID(), name: "Remote Place", coordinates: .london, address: "London", spaceId: remoteSpaceId)
        let localRepo = MockPlaceRepository()
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [remotePlace])
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo)

        await sut.syncAll()

        #expect(localRepo.lastUpsertSpaceId == remoteSpaceId)
    }

    @Test func pullCategoryUsesItsOwnSpaceIdNotAnyLocalNotionOfCurrentSpace() async throws {
        let remoteSpaceId = UUID()
        let remoteCategory = Dropin.Category(id: UUID(), name: "Remote Category", color: "FF0000", icon: .sf("tag"),
                                             createdAt: Date(), updatedAt: Date(), deletedAt: nil, spaceId: remoteSpaceId)
        let localRepo = MockCategoryRepository()
        let remoteRepo = MockRemoteCategoryRepository(categoriesToReturn: [remoteCategory])
        let sut = makeSUT(localCategoryRepo: localRepo, remoteCategoryRepo: remoteRepo)

        await sut.syncAll()

        let lastSpaceId = localRepo.lastUpsertSpaceId
        #expect(lastSpaceId == remoteSpaceId)
    }

    @Test func pullTagUsesItsOwnSpaceIdNotAnyLocalNotionOfCurrentSpace() async throws {
        let remoteSpaceId = UUID()
        let remoteTag = Dropin.Tag(id: UUID(), name: "Remote Tag", color: "0000FF",
                                   createdAt: Date(), updatedAt: Date(), deletedAt: nil, spaceId: remoteSpaceId)
        let localRepo = MockTagRepository()
        let remoteRepo = MockRemoteTagRepository(tagsToReturn: [remoteTag])
        let sut = makeSUT(localTagRepo: localRepo, remoteTagRepo: remoteRepo)

        await sut.syncAll()

        let lastSpaceId = await localRepo.lastUpsertSpaceId
        #expect(lastSpaceId == remoteSpaceId)
    }

    @Test func syncAllPullIsIdempotent() async throws {
        let remotePlace = Place(id: UUID(), name: "Place", coordinates: .london, address: "", spaceId: UUID())
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

    // MARK: - reachability
    // SyncService registers itself as a ReachabilityListener, these go through the
    // mock's `isConnected` setter, not a direct reachabilityDidChange call, so they exercise
    // the same listener-notification path a real reconnection would.

    @Test func reachabilityRestoredTriggersPull() async throws {
        let remotePlace = Place(id: UUID(), name: "Remote Place", coordinates: .london, address: "London", spaceId: UUID())
        let localRepo = MockPlaceRepository()
        let remoteRepo = MockRemotePlaceRepository(placesToReturn: [remotePlace])
        let reachability = MockReachabilityService(isConnected: false)
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo, reachability: reachability)

        reachability.isConnected = true
        await sut.pendingReachabilityTask?.value

        let fetched = try await localRepo.fetch(remotePlace.id)
        #expect(fetched.name == remotePlace.name)
    }

    @Test func reachabilityRestoredPushesChangesQueuedWhileOffline() async throws {
        let place = Place(id: UUID(), name: "Test Place", coordinates: .london, address: "")
        let localRepo = MockPlaceRepository(initialPlaces: [place])
        let remoteRepo = MockRemotePlaceRepository()
        let reachability = MockReachabilityService(isConnected: false)
        let sut = makeSUT(localPlaceRepo: localRepo, remotePlaceRepo: remoteRepo, reachability: reachability)
        sut.markPlaceDirty(place.id)   // queued while offline: push no-ops until reconnection

        reachability.isConnected = true
        await sut.pendingReachabilityTask?.value

        #expect(remoteRepo.upsertedPlaces.map(\.id).contains(place.id))
    }

    @Test func reachabilityLostDoesNotTriggerSync() async throws {
        let reachability = MockReachabilityService(isConnected: true)
        let sut = makeSUT(reachability: reachability)

        reachability.isConnected = false

        #expect(sut.pendingReachabilityTask == nil)
    }
}
