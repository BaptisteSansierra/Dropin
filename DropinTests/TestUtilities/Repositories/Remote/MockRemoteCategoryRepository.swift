//
//  MockRemoteCategoryRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

// `Category` alone is ambiguous here against objc/runtime.h's `typedef struct
// objc_category *Category` (visible in this target but not the app target) —
// qualify with the module name throughout this file.
final class MockRemoteCategoryRepository: RemoteCategoryRepository, @unchecked Sendable {
    private(set) var upsertedCategories: [Dropin.Category] = []
    var categoriesToReturn: [Dropin.Category]
    var shouldThrowOnUpsert = false

    init(categoriesToReturn: [Dropin.Category] = []) {
        self.categoriesToReturn = categoriesToReturn
    }

    func upsert(_ category: Dropin.Category) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedCategories.append(category)
    }

    func fetch(updatedAfter date: Date) async throws -> [Dropin.Category] {
        return categoriesToReturn
    }
}
