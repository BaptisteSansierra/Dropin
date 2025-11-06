//
//  MockTagRepository.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

@MainActor
final class MockTagRepository: TagRepository {
    
    private var tags: [TagEntity]

    init(initialTags: [TagEntity] = []) {
        self.tags = initialTags
    }
    
    func exists(_ place: TagEntity) async throws -> Bool {
        if let _ = tags.first(where: { $0.id == place.id }) {
            return true
        }
        return false
    }
        
    func create(_ tag: TagEntity) async throws {
        tags.append(tag)
    }
    
    func delete(_ tag: TagEntity) async throws {
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        print("Remove tag at index \(index)")
        tags.remove(at: index)
    }
    
    func update(_ tag: TagEntity) async throws {
    }
    
    func getAll() async throws -> [TagEntity] {
        return tags
    }
}
