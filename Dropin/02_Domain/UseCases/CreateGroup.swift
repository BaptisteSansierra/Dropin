//
//  CreateGroup.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
struct CreateGroup {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ group: GroupEntity) async throws {
        guard group.name.count > 0 else {
            throw DomainError.Group.missingName
        }
        if try await repository.exists(group) {
            throw DomainError.Group.alreadyExists
        }
//        if !group.icon.isValid {
//            throw DomainError.Group.undefinedMarker
//        }
        if !group.color.isValidHexaColor {
            throw DomainError.Group.invalidColor
        }
        return try await repository.create(group)
    }
}
