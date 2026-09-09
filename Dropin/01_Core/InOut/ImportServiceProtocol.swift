//
//  ImportServiceProtocol.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

protocol ImportServiceProtocol: Sendable {
    func execute(_ url: URL,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int) -> Void) async throws
}
