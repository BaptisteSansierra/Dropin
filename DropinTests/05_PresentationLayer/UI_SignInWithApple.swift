//
//  UI_SignInWithApple.swift
//  DropinTests
//
//  Created by baptiste sansierra on 25/11/26.
//
//  Sign in with Apple: nonce, SignInViewModel, display name from Apple's full name.
//  The success path is tested through `completeAppleSignIn`: `ASAuthorization` can't be built in tests.
//

import Foundation
import Testing
import SwiftData
import AuthenticationServices
@testable import Dropin

// MARK: - AppleNonce

struct App_AppleNonce {

    private let allowed = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    @Test func randomLengthAndCharset() {
        #expect(AppleNonce.random().count == 32)
        #expect(AppleNonce.random(length: 64).count == 64)
        #expect(AppleNonce.random(length: 1000).allSatisfy { allowed.contains($0) })
    }

    @Test func randomIsRandom() {
        let nonces = Set((0..<100).map { _ in AppleNonce.random() })
        #expect(nonces.count == 100)
    }

    @Test func sha256KnownValues() {
        #expect(AppleNonce.sha256("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(AppleNonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}

// MARK: - SignInViewModel

@MainActor
struct UI_SignInWithApple {

    private let mock = MockContainer()
    private let authService = MockAuthService()

    private func makeViewModel() -> SignInViewModel {
        SignInViewModel(appContainer: mock.appContainer,
                        authService: authService,
                        coordinator: AuthCoordinator())
    }

    private var fullName: PersonNameComponents {
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Doe"
        return name
    }

    // MARK: prepareAppleRequest

    @Test func prepareRequestSetsScopesAndHashedNonce() throws {
        let vm = makeViewModel()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        vm.prepareAppleRequest(request)
        #expect(request.requestedScopes == [.fullName, .email])
        // Apple gets the SHA256 (64 hex characters), never the raw nonce
        let hashed = try #require(request.nonce)
        #expect(hashed.count == 64)
        #expect(hashed.allSatisfy { $0.isHexDigit })
    }

    @Test func prepareRequestUsesANewNonceEachTime() {
        let vm = makeViewModel()
        let first = ASAuthorizationAppleIDProvider().createRequest()
        let second = ASAuthorizationAppleIDProvider().createRequest()
        vm.prepareAppleRequest(first)
        vm.prepareAppleRequest(second)
        #expect(first.nonce != second.nonce)
    }

    // MARK: signInWithApple (Apple sheet result)

    @Test func canceledSheetShowsNoError() async {
        let vm = makeViewModel()
        vm.prepareAppleRequest(ASAuthorizationAppleIDProvider().createRequest())
        await vm.signInWithApple(.failure(ASAuthorizationError(.canceled)))
        #expect(vm.lastAppleError == nil)
        #expect(vm.lastError == nil)
        #expect(authService.appleCalls.isEmpty)
    }

    @Test(arguments: [ASAuthorizationError.Code.failed, .invalidResponse, .unknown])
    func appleErrorShowsAppleFailure(_ code: ASAuthorizationError.Code) async {
        let vm = makeViewModel()
        vm.prepareAppleRequest(ASAuthorizationAppleIDProvider().createRequest())
        await vm.signInWithApple(.failure(ASAuthorizationError(code)))
        #expect(vm.lastAppleError == String(localized: "auth.error.apple_signin_failed"))
        #expect(authService.appleCalls.isEmpty)
        #expect(!vm.isSubmitting)
    }

    @Test func newAttemptClearsThePreviousError() async {
        let vm = makeViewModel()
        await vm.signInWithApple(.failure(ASAuthorizationError(.failed)))
        #expect(vm.lastAppleError != nil)
        await vm.signInWithApple(.failure(ASAuthorizationError(.canceled)))
        #expect(vm.lastAppleError == nil)
    }

    // MARK: completeAppleSignIn (Supabase)

    @Test func signInSendsTokenAndNonce() async {
        let vm = makeViewModel()
        await vm.completeAppleSignIn(idToken: "token", nonce: "raw-nonce", fullName: nil)
        #expect(authService.appleCalls.count == 1)
        #expect(authService.appleCalls.first?.idToken == "token")
        #expect(authService.appleCalls.first?.nonce == "raw-nonce")
        #expect(authService.isAuthenticated)
        #expect(vm.lastAppleError == nil)
        #expect(!vm.isSubmitting)
    }

    @Test func fullNameIsStashedBeforeSigningIn() async {
        let vm = makeViewModel()
        // The session flip runs `loadProfile()`: the name must be stashed before
        var stashedDuringSignIn: String?
        authService.onSignInWithApple = { stashedDuringSignIn = mock.appContainer.pendingDisplayName }
        await vm.completeAppleSignIn(idToken: "token", nonce: "nonce", fullName: fullName)
        let expected = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default)
        #expect(stashedDuringSignIn == expected)
        #expect(mock.appContainer.pendingDisplayName == expected)
    }

    @Test func noFullNameStashesNothing() async {
        let vm = makeViewModel()
        await vm.completeAppleSignIn(idToken: "token", nonce: "nonce", fullName: nil)
        #expect(mock.appContainer.pendingDisplayName == nil)
        // Not the first sign-in: Apple sends empty components
        await vm.completeAppleSignIn(idToken: "token", nonce: "nonce", fullName: PersonNameComponents())
        #expect(mock.appContainer.pendingDisplayName == nil)
    }

    @Test func timeoutShowsTimeoutAndDropsTheName() async {
        let vm = makeViewModel()
        authService.appleError = AuthServiceError.signInTimedOut
        await vm.completeAppleSignIn(idToken: "token", nonce: "nonce", fullName: fullName)
        #expect(vm.lastAppleError == String(localized: "auth.error.timeout"))
        #expect(mock.appContainer.pendingDisplayName == nil)
        #expect(!vm.isSubmitting)
    }

    @Test func otherErrorShowsItsDescriptionAndDropsTheName() async {
        let vm = makeViewModel()
        let error = URLError(.notConnectedToInternet)
        authService.appleError = error
        await vm.completeAppleSignIn(idToken: "token", nonce: "nonce", fullName: fullName)
        #expect(vm.lastAppleError == error.localizedDescription)
        #expect(mock.appContainer.pendingDisplayName == nil)
        #expect(!vm.isSubmitting)
    }
}

// MARK: - loadProfile: pending display name

@MainActor
struct App_PendingDisplayName {

    /// Profile service whose loaded profile has `displayName`
    @MainActor
    private final class ProfileServiceSpy: ProfileServiceProtocol {
        var profile: Profile?
        private let loadedDisplayName: String?
        private(set) var setDisplayNameCalls: [String?] = []

        init(loadedDisplayName: String?) { self.loadedDisplayName = loadedDisplayName }

        func load() async {
            profile = Profile(id: UUID(), email: "john.doe@example.com", displayName: loadedDisplayName,
                              plan: .earlyStage, createdAt: .now, updatedAt: .now)
        }
        func setDisplayName(_ newValue: String?) async throws {
            setDisplayNameCalls.append(newValue)
        }
        func clear() { profile = nil }
    }

    /// Same setup as MockContainer, with the given profile service
    private func makeContainer(_ profileService: ProfileServiceSpy) throws -> (AppContainer, ModelContainer) {
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
                                     profileService: profileService,
                                     authService: StubAuthService())
        // The model container must outlive the test
        return (container, modelContainer)
    }

    @Test func pendingNameFillsAnEmptyProfile() async throws {
        let spy = ProfileServiceSpy(loadedDisplayName: nil)
        let (container, modelContainer) = try makeContainer(spy)
        container.pendingDisplayName = "John Doe"
        await container.loadProfile()
        #expect(spy.setDisplayNameCalls == ["John Doe"])
        #expect(container.pendingDisplayName == nil)
        withExtendedLifetime(modelContainer) {}
    }

    @Test func pendingNameNeverOverwritesAName() async throws {
        let spy = ProfileServiceSpy(loadedDisplayName: "Johnny")
        let (container, modelContainer) = try makeContainer(spy)
        container.pendingDisplayName = "John Doe"
        await container.loadProfile()
        #expect(spy.setDisplayNameCalls.isEmpty)
        // Consumed anyway: not applied on a later load
        #expect(container.pendingDisplayName == nil)
        withExtendedLifetime(modelContainer) {}
    }

    @Test func noPendingNameChangesNothing() async throws {
        let spy = ProfileServiceSpy(loadedDisplayName: nil)
        let (container, modelContainer) = try makeContainer(spy)
        await container.loadProfile()
        #expect(spy.setDisplayNameCalls.isEmpty)
        withExtendedLifetime(modelContainer) {}
    }
}
