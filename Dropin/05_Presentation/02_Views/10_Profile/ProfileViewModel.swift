//
//  ProfileViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class ProfileViewModel {

    // MARK: - Sign-out flow state
    /// Set after first attempt that requires user confirmation (offline or
    /// post-sync still pending). Drives the second confirmation alert.
    var pendingForceSignOut: ForceSignOutReason?

    var isSigningOut: Bool = false

    enum ForceSignOutReason: Equatable {
        case offline(pendingCount: Int)
        case syncFailed(pendingCount: Int)

        var pendingCount: Int {
            switch self {
                case .offline(let n), .syncFailed(let n): return n
            }
        }
    }

    /// Not private/ObservationIgnored — the view binds `$viewModel.coordinator.path`
    /// to its own NavigationStack (same pattern as SignInViewModel/AuthCoordinator).
    var coordinator: ProfileCoordinator

    @ObservationIgnored private let appContainer: AppContainer
    @ObservationIgnored private let profileService: any ProfileServiceProtocol

    init(appContainer: AppContainer,
         profileService: any ProfileServiceProtocol,
         coordinator: ProfileCoordinator) {
        self.appContainer = appContainer
        self.profileService = profileService
        self.coordinator = coordinator
    }

    // MARK: - Read-only fields surfaced to the view
    var profile: ProfileEntity? { profileService.profile }
    var displayName: String { profile?.displayName ?? "" }
    var email: String? { profile?.email }
    var plan: UserPlan? { profile?.plan }

    var avatarInitial: String {
        let placeholder = "N/A"
        let source = displayName.isEmpty ? placeholder : displayName.initials()
        return source.uppercased()
    }

    // MARK: - Navigation
    func pushEditDisplayName() {
        coordinator.pushEditName()
    }

    func pushAccountDeletion() {
        coordinator.pushAccountDeletion()
    }

    func createEditDisplayNameView() -> EditDisplayNameView {
        appContainer.createEditDisplayNameView()
    }

    func createDeleteAccountView() -> DeleteAccountView {
        appContainer.createDeleteAccountView()
    }

    // MARK: - Sign out

    /// First-pass sign-out. Throws if user confirmation is required (the view
    /// stages a second alert via `pendingForceSignOut` based on the error).
    func signOut(didStartClearingSession: () -> Void) async {
        isSigningOut = true
        defer { isSigningOut = false }
        do {
            try await appContainer.signOut {
                didStartClearingSession()
            }
        } catch let AppContainer.SignOutError.offlineWithPendingChanges(count) {
            pendingForceSignOut = .offline(pendingCount: count)
        } catch let AppContainer.SignOutError.syncFailedWithPendingChanges(count) {
            pendingForceSignOut = .syncFailed(pendingCount: count)
        } catch {
            Log.error("ProfileViewModel: signOut failed: \(error)")
        }
    }

    /// Second-pass: user accepted that unsynced changes will be lost.
    func forceSignOut(didStartClearingSession: () -> Void) async {
        isSigningOut = true
        defer { isSigningOut = false }
        pendingForceSignOut = nil
        do {
            try await appContainer.signOut(force: true,
                                           didStartClearingSession: didStartClearingSession)
        } catch {
            Log.error("ProfileViewModel: forced signOut failed: \(error)")
        }
    }
}
