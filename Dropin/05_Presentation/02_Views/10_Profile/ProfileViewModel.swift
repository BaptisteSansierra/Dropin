//
//  ProfileViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class ProfileViewModel {

    // MARK: - Edit state for display name (auto-save)
    var draft: String = ""
    private(set) var lastSaved: String = ""

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

    @ObservationIgnored private let appContainer: AppContainer
    @ObservationIgnored private let profileService: any ProfileServiceProtocol
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(appContainer: AppContainer,
         profileService: any ProfileServiceProtocol) {
        self.appContainer = appContainer
        self.profileService = profileService
        let current = profileService.profile?.displayName ?? ""
        self.draft = current
        self.lastSaved = current
    }

    // MARK: - Read-only fields surfaced to the view
    var profile: ProfileEntity? { profileService.profile }
    var email: String? { profile?.email }
    var plan: UserPlan? { profile?.plan }
    
    var avatarInitial: String {
        let placeholder = "N/A"
        let source = draft.isEmpty ? placeholder : draft.initials()
        return source.uppercased()
    }

    // MARK: - Validation
    var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Localized validation error, nil if valid.
    var validationError: LocalizedStringResource? {
        if trimmed.isEmpty { return LocalizedStringResource("profile.error.name_empty") }
        if trimmed.count > 50 { return LocalizedStringResource("profile.error.name_too_long") }
        return nil
    }

    var isValid: Bool { validationError == nil }
    var hasUnsavedChanges: Bool { trimmed != lastSaved }

    // MARK: - Save (debounced)
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard let self else { return }
            guard !Task.isCancelled else { return }
            await self.commitIfValid()
        }
    }

    func saveNow() async {
        saveTask?.cancel()
        await commitIfValid()
    }

    private func commitIfValid() async {
        guard isValid, hasUnsavedChanges else { return }
        let toSave = trimmed
        do {
            try await profileService.setDisplayName(toSave)
            lastSaved = toSave
        } catch {
            Log.error("ProfileViewModel: setDisplayName failed: \(error)")
        }
    }

    /// Called from `.onDisappear`; if the draft is currently invalid, revert it
    /// to the last-saved value so we don't keep stale bad state.
    func discardInvalidDraftOnDismiss() {
        if !isValid { draft = lastSaved }
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
