//
//  Domain_Space.swift
//  DropinTests
//

import Testing
import Foundation
@testable import Dropin

struct Domain_Space {

    private func makeSpace(deletedAt: Date? = nil) -> Space {
        Space(id: UUID(), name: "Secondary", color: "588B8B", icon: .sf("house"),
             ownerId: UUID(),
             createdAt: Date(timeIntervalSince1970: 1_700_000_000),
             updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
             deletedAt: deletedAt)
    }

    @Test func deletedOnlyTouchesDeletedAt() {
        let original = makeSpace()
        let deletedAt = Date(timeIntervalSince1970: 1_800_000_000)

        let deleted = original.deleted(deletedAt: deletedAt)

        #expect(deleted.deletedAt == deletedAt)
        #expect(deleted.id == original.id)
        #expect(deleted.name == original.name)
        #expect(deleted.updatedAt == original.updatedAt)
    }

    @Test func updatedOnlyBumpsUpdatedAt() {
        let original = makeSpace()

        let updated = original.updated()

        #expect(updated.updatedAt > original.updatedAt)
        #expect(updated.id == original.id)
        #expect(updated.name == original.name)
        #expect(updated.deletedAt == original.deletedAt)
    }

    @Test func isActiveReflectsDeletedAt() {
        #expect(makeSpace(deletedAt: nil).isActive)
        #expect(!makeSpace(deletedAt: Date()).isActive)
    }

    @Test func equalityAndHashingAreByIdOnly() {
        let id = UUID()
        let a = Space(id: id, name: "Secondary", color: "588B8B", icon: .sf("house"),
                     ownerId: UUID(), createdAt: Date(), updatedAt: Date(), deletedAt: nil)
        let b = Space(id: id, name: "Renamed", color: "000000", icon: .sf("briefcase"),
                     ownerId: UUID(), createdAt: Date(), updatedAt: Date(), deletedAt: Date())

        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    // Regression: Space.mainId represents the user's personal, implicit space — it must
    // never collide with a real, randomly-generated Space id.
    @Test func mainIdIsFixedAndNeverMatchesARandomId() {
        #expect(Space.mainId == UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        #expect(Space.mainId != UUID())
    }
}
