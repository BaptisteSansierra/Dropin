//
//  RollbackContext.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/9/26.
//

import Foundation

@MainActor
struct RollbackContext {
    private let repository: GeneralRepository

    init(repository: GeneralRepository) {
        self.repository = repository
    }

    func callAsFunction() async {
        await repository.rollback()
    }
}
