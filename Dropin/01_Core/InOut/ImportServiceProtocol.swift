//
//  ImportServiceProtocol.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//
//  Two-phase: `read` parses the file and returns a Plan, writing nothing.
//  `import` writes the plan. Splitting lets a caller inspect/edit the plan
//  (e.g. Mapstr's tag-to-category mapping screen) between the two phases.
//  A caller that has nothing to show in between (Dropin) just calls both
//  back-to-back.
//

import Foundation

protocol ImportServiceProtocol: Sendable {
    associatedtype Plan: Sendable

    func read(_ url: URL) async throws -> Plan
    func read(_ data: Data) async throws -> Plan

    func `import`(_ plan: Plan,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws
}
