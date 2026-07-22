//
//  EditDisplayNameViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class EditDisplayNameViewModel {

    var name: String
    var isSaving: Bool = false

    @ObservationIgnored private let profileService: any ProfileServiceProtocol
    @ObservationIgnored private let coordinator: ProfileCoordinator
    @ObservationIgnored private let original: String

    init(profileService: any ProfileServiceProtocol, coordinator: ProfileCoordinator) {
        self.profileService = profileService
        self.coordinator = coordinator
        let current = profileService.profile?.displayName ?? ""
        self.name = current
        self.original = current
    }

    var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { (2...30).contains(trimmed.count) }
    var canSave: Bool { isValid && trimmed != original && !isSaving }

    func clear() {
        name = ""
    }

    func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await profileService.setDisplayName(trimmed)
            coordinator.pop()
        } catch {
            Log.error("EditDisplayNameViewModel: setDisplayName failed: \(error)")
        }
    }

    func pop() {
        coordinator.pop()
    }
}
