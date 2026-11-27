//
//  UI_DeleteAccountApple.swift
//  DropinTests
//
//  Created by baptiste sansierra on 26/11/26.
//
//  Account deletion of a Sign in with Apple user: Apple confirmation first, its code sent to the backend.
//

import Foundation
import Testing
import SwiftData
import AuthenticationServices
@testable import Dropin

@MainActor
struct UI_DeleteAccountApple {

    /// Returns `code`, or throws `error` when set
    @MainActor
    private final class AppleReauthorizationSpy: AppleReauthorizationProtocol {
        var code = "apple-code"
        var error: Error?
        private(set) var calls = 0

        func authorizationCode() async throws -> String {
            calls += 1
            if let error { throw error }
            return code
        }
    }

    private let authService = MockAuthService()
    private let apple = AppleReauthorizationSpy()

    /// Same setup as MockContainer, with `authService`. The model container must outlive the test
    private func makeViewModel() throws -> (DeleteAccountViewModel, ModelContainer) {
        let modelContainer = try ModelContainer(for: PlaceRecord.self, TagRecord.self, CategoryRecord.self,
                                                PlaceImageRecord.self, ProfileRecord.self, SpaceRecord.self,
                                                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext
        modelContext.autosaveEnabled = false
        try AppContainer.insertMockData(modelContext: modelContext)
        let locationManager = LocationManager()
        let container = AppContainer(modelContext: modelContext,
                                     appContext: AppContext(),
                                     locationManager: locationManager,
                                     addressLookupService: AddressLookupService(locationManager: locationManager),
                                     reachabilityService: StubReachabilityService(),
                                     profileService: StubProfileService(),
                                     authService: authService)
        let vm = DeleteAccountViewModel(appContainer: container,
                                        coordinator: ProfileCoordinator(),
                                        fetchPlaces: FetchPlaces(repository: MockPlaceRepository()),
                                        fetchCategories: FetchCategories(repository: MockCategoryRepository()),
                                        fetchTags: FetchTags(repository: MockTagRepository()),
                                        imageRepository: PlaceImageRepositoryImpl(modelContext: modelContext),
                                        appleReauthorization: apple)
        vm.agreementText = vm.confirmToken
        return (vm, modelContainer)
    }

    @Test func emailUserDeletesWithoutApple() async throws {
        let (vm, modelContainer) = try makeViewModel()
        await vm.confirmDelete()
        #expect(apple.calls == 0)
        #expect(authService.deleteCalls == [nil])
        #expect(vm.deleteError == nil)
        withExtendedLifetime(modelContainer) {}
    }

    @Test func appleUserSendsTheAppleCode() async throws {
        authService.hasAppleIdentity = true
        let (vm, modelContainer) = try makeViewModel()
        await vm.confirmDelete()
        #expect(apple.calls == 1)
        #expect(authService.deleteCalls == ["apple-code"])
        #expect(vm.deleteError == nil)
        #expect(!vm.isDeleting)
        withExtendedLifetime(modelContainer) {}
    }

    @Test func canceledAppleSheetDeletesNothing() async throws {
        authService.hasAppleIdentity = true
        apple.error = ASAuthorizationError(.canceled)
        let (vm, modelContainer) = try makeViewModel()
        await vm.confirmDelete()
        #expect(authService.deleteCalls.isEmpty)
        #expect(vm.deleteError == nil)
        #expect(!vm.isDeleting)
        withExtendedLifetime(modelContainer) {}
    }

    @Test func appleFailureDeletesNothing() async throws {
        authService.hasAppleIdentity = true
        apple.error = ASAuthorizationError(.failed)
        let (vm, modelContainer) = try makeViewModel()
        await vm.confirmDelete()
        #expect(authService.deleteCalls.isEmpty)
        #expect(vm.deleteError == String(localized: "delete_account.error.generic"))
        withExtendedLifetime(modelContainer) {}
    }

    @Test func backendFailureShowsTheGenericError() async throws {
        authService.hasAppleIdentity = true
        authService.deleteError = URLError(.badServerResponse)
        let (vm, modelContainer) = try makeViewModel()
        await vm.confirmDelete()
        #expect(authService.deleteCalls == ["apple-code"])
        #expect(vm.deleteError == String(localized: "delete_account.error.generic"))
        withExtendedLifetime(modelContainer) {}
    }
}
