//
//  GeneralRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/9/26.
//

import Foundation
import SwiftData

public final class GeneralRepositoryImpl: GeneralRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save() async throws {
        try modelContext.save()
    }

    func rollback() async {
        modelContext.rollback()
    }
}
