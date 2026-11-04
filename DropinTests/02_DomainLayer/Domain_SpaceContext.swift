//
//  Domain_SpaceContext.swift
//  DropinTests
//

import Testing
import Foundation
@testable import Dropin

struct Domain_SpaceContext {

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    @Test func defaultsToPersonalSpaceWhenNothingStored() {
        let sut = SpaceContext(userDefaults: freshDefaults())

        #expect(sut.currentSpaceId == Space.mainId)
    }

    @Test func picksUpPreviouslyStoredCurrentSpaceId() {
        let storedSpaceId = UUID()
        let defaults = freshDefaults()
        defaults.set(storedSpaceId.uuidString, forKey: DropinApp.userDefaultsKeys.currentSpaceId)

        let sut = SpaceContext(userDefaults: defaults)

        #expect(sut.currentSpaceId == storedSpaceId)
    }

    @Test func setCurrentUpdatesAndPersists() {
        let newSpaceId = UUID()
        let defaults = freshDefaults()
        let sut = SpaceContext(userDefaults: defaults)

        sut.setCurrent(newSpaceId)

        #expect(sut.currentSpaceId == newSpaceId)
        // A freshly-constructed context (same UserDefaults) picks up the persisted value.
        let reloaded = SpaceContext(userDefaults: defaults)
        #expect(reloaded.currentSpaceId == newSpaceId)
    }
}
