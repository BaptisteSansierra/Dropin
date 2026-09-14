//
//  MockGeneralRepository.swift
//  DropinTests
//
//  Created by baptiste sansierra on 14/9/26.
//

import Foundation
@testable import Dropin

@MainActor
final class MockGeneralRepository: GeneralRepository {
    
    func save() async throws { }

    func rollback() async { }
}
