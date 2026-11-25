//
//  SpaceContext.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//
//  Plain holder for the two space ids every space-scoped repository needs.
//

import Foundation

final class SpaceContext {
    private(set) var currentSpaceId: UUID
    private let userDefaults: UserDefaults

    /// Defaults to `Space.mainId` (the user's personal, non-stored space) when nothing's
    /// been stored yet — no local/remote lookup needed to resolve it.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let stored = userDefaults.string(forKey: DropinApp.userDefaultsKeys.currentSpaceId),
           let storedId = UUID(uuidString: stored) {
            self.currentSpaceId = storedId
        } else {
            self.currentSpaceId = Space.mainId
        }
    }

    func setCurrent(_ id: UUID) {
        currentSpaceId = id
        userDefaults.set(id.uuidString, forKey: DropinApp.userDefaultsKeys.currentSpaceId)
    }
}
