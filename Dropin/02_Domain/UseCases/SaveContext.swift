//
//  SaveContext.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/9/26.
//

import Foundation

@MainActor
struct SaveContext {
    private let repository: GeneralRepository

    init(repository: GeneralRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws {
        try await repository.save()
    }
}
