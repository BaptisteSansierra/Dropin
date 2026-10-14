//
//  PlacesMapViewModelTests.swift
//  DropinTests
//
//  Covers draftDuplicate/draftOverlap (private) indirectly through the
//  public presentQuickCreateSheet entry point.
//

import Testing
import Foundation
import CoreLocation
import SwiftUI
import SwiftData
@testable import Dropin

@MainActor
private func makeViewModel() throws -> PlacesMapViewModel {
    let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(for: PlaceRecord.self, TagRecord.self, CategoryRecord.self,
                                            PlaceImageRecord.self, ProfileRecord.self,
                                            configurations: modelConfiguration)
    let modelContext = modelContainer.mainContext
    let locationManager = LocationManager()
    let appContainer = AppContainer(modelContext: modelContext,
                                    appContext: AppContext(),
                                    locationManager: locationManager,
                                    addressLookupService: AddressLookupService(locationManager: locationManager),
                                    reachabilityService: StubReachabilityService(),
                                    profileService: StubProfileService())
    return PlacesMapViewModel(appContainer, coordinator: PlaceCoordinator(), locationManager: locationManager)
}

@MainActor
private func makePlace(id: UUID = UUID(),
                       name: String,
                       coordinates: CLLocationCoordinate2D,
                       applePlaceID: String? = nil,
                       deletedAt: Date? = nil) -> PlaceUIModel {
    let now = Date()
    return PlaceUIModel(id: id,
                        name: name,
                        coordinates: coordinates,
                        address: nil,
                        address2: nil,
                        tags: [],
                        applePlaceID: applePlaceID,
                        createdAt: now,
                        updatedAt: now,
                        deletedAt: deletedAt)
}

@MainActor
private func draftBinding(_ initial: PlaceUIModel?) -> (Binding<PlaceUIModel?>, () -> PlaceUIModel?) {
    var current = initial
    let binding = Binding<PlaceUIModel?>(get: { current }, set: { current = $0 })
    return (binding, { current })
}

@MainActor
struct PlacesMapViewModelTests {

    @Test func duplicateDetectedBySameNameAndCoordsCaseInsensitive() throws {
        let vm = try makeViewModel()
        let existing = makePlace(name: "La Chitarra", coordinates: .barcelona)
        let draft = makePlace(name: "la chitarra", coordinates: .barcelona)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(vm.isPresentingDuplicatingPlace)
        #expect(vm.duplicatingPlace?.id == existing.id)
        #expect(currentDraft() == nil)
        #expect(!vm.showQuickCreateSheet)
    }

    @Test func duplicateDetectedBySameApplePlaceIDRegardlessOfNameOrPosition() throws {
        let vm = try makeViewModel()
        let existing = makePlace(name: "Starbucks Uptown", coordinates: .barcelona, applePlaceID: "abc123")
        let draft = makePlace(name: "Starbucks Downtown", coordinates: .paris, applePlaceID: "abc123")
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(vm.isPresentingDuplicatingPlace)
        #expect(vm.duplicatingPlace?.id == existing.id)
    }

    @Test func overlapDetectedWithinThreeMeters() throws {
        let vm = try makeViewModel()
        let existing = makePlace(name: "Existing Place", coordinates: .barcelona)
        let nearby = CLLocationCoordinate2D.barcelona.offset(x: 0.00002, y: 0) // ~2.2m away
        let draft = makePlace(name: "Totally Different Name", coordinates: nearby)
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(vm.isPresentingOverlapingPlace)
        #expect(vm.overlapingPlace?.id == existing.id)
    }

    @Test func noOverlapBeyondThreeMeters() throws {
        let vm = try makeViewModel()
        let existing = makePlace(name: "Existing Place", coordinates: .barcelona)
        let far = CLLocationCoordinate2D.barcelona.offset(x: 0.00005, y: 0) // ~5.6m away
        let draft = makePlace(name: "Totally Different Name", coordinates: far)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
        #expect(currentDraft()?.id == draft.id)
    }

    @Test func distinctPlaceShowsQuickCreateSheet() throws {
        let vm = try makeViewModel()
        let existing = makePlace(name: "Existing Place", coordinates: .barcelona)
        let draft = makePlace(name: "New Place", coordinates: .paris)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
        #expect(currentDraft()?.id == draft.id)
    }

    @Test func deletedPlacesAreIgnoredForDuplicateAndOverlap() throws {
        let vm = try makeViewModel()
        let deletedExisting = makePlace(name: "Same Name", coordinates: .barcelona, deletedAt: Date())
        let draft = makePlace(name: "Same Name", coordinates: .barcelona)
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [deletedExisting])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
    }
}
