//
//  ProfileViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class ProfileViewModel {

    // MARK: - Sign-out flow state
    /// Set after first attempt that requires user confirmation (offline or post-sync still pending).
    /// Drives the second confirmation alert.
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

    var coordinator: ProfileCoordinator

    var displayName: String
    var email: String
    var plan: UserPlan
    var avatarInitial: String {
        let placeholder = "-"
        var source = placeholder
        if !displayName.isEmpty {
            source = displayName.initials()
        }
        return source.uppercased()
    }

    @ObservationIgnored private let appContainer: AppContainer
    @ObservationIgnored private let profileService: any ProfileServiceProtocol

    // MARK: init
    init(appContainer: AppContainer,
         profileService: any ProfileServiceProtocol,
         coordinator: ProfileCoordinator) {
        self.appContainer = appContainer
        self.profileService = profileService
        self.coordinator = coordinator
        if let p = profileService.profile {
            displayName = p.displayName ?? ""
            email = p.email ?? ""
            plan = p.plan
        } else {
            displayName = ""
            email = ""
            plan = .free
        }
    }
    
    func updateProfile() {
        guard let p = profileService.profile else {
            return
        }
        displayName = p.displayName ?? ""
        email = p.email ?? ""
        plan = p.plan
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
