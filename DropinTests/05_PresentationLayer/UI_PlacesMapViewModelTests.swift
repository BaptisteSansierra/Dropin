//
//  UI_PlacesMapViewModelTests.swift
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
struct UI_PlacesMapViewModelTests {

    private func draftBinding(_ initial: PlaceUIModel?) -> (Binding<PlaceUIModel?>, () -> PlaceUIModel?) {
        var current = initial
        let binding = Binding<PlaceUIModel?>(get: { current }, set: { current = $0 })
        return (binding, { current })
    }
    
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

    @Test func duplicateDetectedBySameNameAndCoordsCaseInsensitive() throws {
        let vm = try makeViewModel()
        let existing = SampleData.makePlace(name: "La Chitarra", coordinates: .barcelona)
        let draft = SampleData.makePlace(name: "la chitarra", coordinates: .barcelona)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(vm.isPresentingDuplicatingPlace)
        #expect(vm.duplicatingPlace?.id == existing.id)
        #expect(currentDraft() == nil)
        #expect(!vm.showQuickCreateSheet)
    }

    @Test func duplicateDetectedBySameApplePlaceIDRegardlessOfNameOrPosition() throws {
        let vm = try makeViewModel()
        let existing = SampleData.makePlace(name: "Starbucks Uptown", coordinates: .barcelona, applePlaceID: "abc123")
        let draft = SampleData.makePlace(name: "Starbucks Downtown", coordinates: .paris, applePlaceID: "abc123")
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(vm.isPresentingDuplicatingPlace)
        #expect(vm.duplicatingPlace?.id == existing.id)
    }

    @Test func overlapDetectedWithinThreeMeters() throws {
        let vm = try makeViewModel()
        let existing = SampleData.makePlace(name: "Existing Place", coordinates: .barcelona)
        let nearby = CLLocationCoordinate2D.barcelona.offset(x: 0.00002, y: 0) // ~2.2m away
        let draft = SampleData.makePlace(name: "Totally Different Name", coordinates: nearby)
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(vm.isPresentingOverlapingPlace)
        #expect(vm.overlapingPlace?.id == existing.id)
    }

    @Test func noOverlapBeyondThreeMeters() throws {
        let vm = try makeViewModel()
        let existing = SampleData.makePlace(name: "Existing Place", coordinates: .barcelona)
        let far = CLLocationCoordinate2D.barcelona.offset(x: 0.00005, y: 0) // ~5.6m away
        let draft = SampleData.makePlace(name: "Totally Different Name", coordinates: far)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
        #expect(currentDraft()?.id == draft.id)
    }

    @Test func distinctPlaceShowsQuickCreateSheet() throws {
        let vm = try makeViewModel()
        let existing = SampleData.makePlace(name: "Existing Place", coordinates: .barcelona)
        let draft = SampleData.makePlace(name: "New Place", coordinates: .paris)
        let (binding, currentDraft) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [existing])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
        #expect(currentDraft()?.id == draft.id)
    }

    @Test func deletedPlacesAreIgnoredForDuplicateAndOverlap() throws {
        let vm = try makeViewModel()
        let deletedExisting = SampleData.makePlace(name: "Same Name", coordinates: .barcelona, deletedAt: Date())
        let draft = SampleData.makePlace(name: "Same Name", coordinates: .barcelona)
        let (binding, _) = draftBinding(draft)

        vm.presentQuickCreateSheet(draftPlace: binding, places: [deletedExisting])

        #expect(!vm.isPresentingDuplicatingPlace)
        #expect(!vm.isPresentingOverlapingPlace)
        #expect(vm.showQuickCreateSheet)
    }
}
