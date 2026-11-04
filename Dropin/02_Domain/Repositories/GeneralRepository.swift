//
//  GeneralRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/9/26.
//

import Foundation

@MainActor
protocol GeneralRepository: Sendable {
    func save() async throws
    func rollback() async
}
