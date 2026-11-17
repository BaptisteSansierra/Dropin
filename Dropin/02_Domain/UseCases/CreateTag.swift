//
//  CreateTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
struct CreateTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ tag: Tag) async throws {
        let tag = tag.trimmingName()
        guard !tag.name.isEmpty else {
            throw DomainError.Tag.missingName
        }
        if try await repository.exists(tag) {
            throw DomainError.Tag.alreadyExists
        }
        if try await repository.nameExists(tag.name, excluding: nil) {
            throw DomainError.Tag.nameAlreadyExists
        }
        if !tag.color.isValidHexaColor {
            throw DomainError.Tag.invalidColor
        }
        try await repository.create(tag)
    }
}
