//
//  MapstrImportConfigViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/9/26.
//

import Foundation

@MainActor
@Observable final class MapstrImportConfigViewModel {

    var groupName: String
    var showingNameUpdatedAlert = false
    private(set) var confirmedCategoryName: String?

    @ObservationIgnored private let fetchCategories: FetchCategories

    init(baseName: String, fetchCategories: FetchCategories) {
        self.groupName = baseName
        self.fetchCategories = fetchCategories
    }

    var isConfirmDisabled: Bool {
        groupName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Runs once when the sheet appears: silently resolves the base name to
    /// a unique one if it's already taken. No alert — the user hasn't typed
    /// anything yet, so there's nothing for them to review.
    func resolveInitialName() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let activeNames = await activeCategoryNames()
        guard activeNames.contains(trimmed) else { return }
        groupName = uniqueCandidate(for: trimmed, avoiding: activeNames)
    }

    /// Called when the category name field loses focus (keyboard dismissed).
    /// Only adjusts the name if needed — never confirms.
    func handleKeyboardDismiss() async {
        await ensureUnique(confirmIfAlreadyUnique: false)
    }

    /// Called when the user taps "Next". Confirms immediately if the name is
    /// already unique; otherwise adjusts it, surfaces the alert, and leaves
    /// the user on the form to review before trying again.
    func nextTapped() async {
        await ensureUnique(confirmIfAlreadyUnique: true)
    }

    @discardableResult
    private func ensureUnique(confirmIfAlreadyUnique: Bool) async -> Bool {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let activeNames = await activeCategoryNames()

        guard activeNames.contains(trimmed) else {
            if confirmIfAlreadyUnique {
                confirmedCategoryName = trimmed
            }
            return true
        }

        groupName = uniqueCandidate(for: trimmed, avoiding: activeNames)
        showingNameUpdatedAlert = true
        return false
    }

    private func activeCategoryNames() async -> Set<String> {
        do {
            return Set(try await fetchCategories()
                .filter { $0.isActive }
                .map(\.name))
        } catch {
            Log.error("MapstrImportConfigViewModel: fetchCategories failed: \(error)")
            return []
        }
    }

    private func uniqueCandidate(for base: String, avoiding taken: Set<String>) -> String {
        var index = 1
        var candidate: String
        repeat {
            candidate = "\(base)_\(String(format: "%02d", index))"
            index += 1
        } while taken.contains(candidate)
        return candidate
    }
}
