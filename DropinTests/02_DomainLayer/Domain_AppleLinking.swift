//
//  Domain_AppleLinking.swift
//  DropinTests
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

struct Domain_AppleLinking {

    private func makePlace(applePlaceID: String? = "abc123",
                           appleNotFoundAt: Date? = nil,
                           deletedAt: Date? = nil) -> Place {
        Place(id: UUID(),
             name: "Test Place",
             coordinates: .barcelona,
             address: nil,
             address2: nil,
             tags: [],
             category: nil,
             images: [],
             icon: nil,
             rating: nil,
             phone: [],
             email: [],
             url: [],
             notes: nil,
             applePlaceID: applePlaceID,
             appleNotFoundAt: appleNotFoundAt,
             createdAt: Date(),
             updatedAt: Date(),
             deletedAt: deletedAt)
    }

    // MARK: - withAppleNotFoundAt

    @Test func withAppleNotFoundAtSetsExactDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let original = makePlace(appleNotFoundAt: nil)
        let updated = original.withAppleNotFoundAt(notFoundAt: date)
        #expect(updated.appleNotFoundAt == date)
    }

    // Regression: an earlier version of this method mistakenly wrote `deletedAt`
    // into `appleNotFoundAt` instead of the `notFoundAt` parameter.
    @Test func withAppleNotFoundAtDoesNotTouchDeletedAt() {
        let deletedAt = Date(timeIntervalSince1970: 1_600_000_000)
        let notFoundAt = Date(timeIntervalSince1970: 1_700_000_000)
        let original = makePlace(appleNotFoundAt: nil, deletedAt: deletedAt)
        let updated = original.withAppleNotFoundAt(notFoundAt: notFoundAt)
        #expect(updated.appleNotFoundAt == notFoundAt)
        #expect(updated.deletedAt == deletedAt)
        #expect(updated.appleNotFoundAt != updated.deletedAt)
    }

    @Test func withAppleNotFoundAtPreservesOtherFields() {
        let original = makePlace()
        let updated = original.withAppleNotFoundAt(notFoundAt: Date())
        #expect(updated.id == original.id)
        #expect(updated.name == original.name)
        #expect(updated.applePlaceID == original.applePlaceID)
    }

    // MARK: - withUnlinkedPOI

    @Test func withUnlinkedPOIClearsApplePlaceID() {
        let original = makePlace(applePlaceID: "abc123")
        let updated = original.withUnlinkedPOI()
        #expect(updated.applePlaceID == nil)
    }

    @Test func withUnlinkedPOIPreservesOtherFields() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let original = makePlace(applePlaceID: "abc123", appleNotFoundAt: date)
        let updated = original.withUnlinkedPOI()
        #expect(updated.id == original.id)
        #expect(updated.name == original.name)
        #expect(updated.appleNotFoundAt == date)
    }
}
