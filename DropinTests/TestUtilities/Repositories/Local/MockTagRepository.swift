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
    
    private var tags: [Dropin.Tag]

    init(initialTags: [Dropin.Tag] = []) {
        self.tags = initialTags
    }
    
    func exists(_ place: Dropin.Tag) async throws -> Bool {
        if let _ = tags.first(where: { $0.id == place.id }) {
            return true
        }
        return false
    }
        
    func create(_ tag: Dropin.Tag) async throws {
        tags.append(tag)
    }
    
    /*
    func delete(_ tag: Dropin.Tag) async throws {
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        Log.info("Remove tag at index \(index)")
        tags.remove(at: index)
    }
     */
    
    func update(_ tag: Dropin.Tag) async throws {
    }
    
    func fetch() async throws -> [Dropin.Tag] {
        return tags
    }
    
    func fetchWithPlaceCount() async throws -> [(Dropin.Tag, Int)] {
        return tags.map({ ($0, 0) }) // dummy impl
    }
    
    func fetch(_ id: UUID) async throws -> Dropin.Tag {
        guard let g = tags.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return g
    }
    
    func upsert(_ tag: Dropin.Tag, shouldSave: Bool) async throws {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index] = tag
        } else {
            tags.append(tag)
        }
    }
    
    func clearTable() async throws {
        tags.removeAll()
    }
}
