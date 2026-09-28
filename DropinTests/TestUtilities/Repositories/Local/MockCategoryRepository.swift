//
//  MockCategoryRepository.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

@MainActor
final class MockCategoryRepository: CategoryRepository {
    
    private var categories: [Dropin.Category]
    //private var allPlaces: [Place]

//    init(initialCategories: [Category] = [], allPlaces: [Place]) {
//        self.categories = initialCategories
//        self.allPlaces = allPlaces
//    }
    init(initialCategories: [Dropin.Category] = []) {
        self.categories = initialCategories
    }

    func exists(_ place: Dropin.Category) async throws -> Bool {
        if let _ = categories.first(where: { $0.id == place.id }) {
            return true
        }
        return false
    }
    
    func create(_ category: Dropin.Category) async throws {
        categories.append(category)
    }
    
    /*
    func delete(_ category: Dropin.Category) async throws {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        Log.info("Remove category at index \(index)")
        categories.remove(at: index)
    }
     */
    
    func update(_ category: Dropin.Category) async throws {
    }
    
    func fetch() async throws -> [Dropin.Category] {
        return categories
    }
    
    func fetchWithPlaceCount() async throws -> [(Dropin.Category, Int)] {
        return categories
            .map({ ($0, 0) }) // dummy impl
    }

    func fetch(_ id: UUID) async throws -> Dropin.Category {
        guard let g = categories.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return g
    }
    
    func upsert(_ category: Dropin.Category, shouldSave: Bool) async throws {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
    }
    
    func clearTable() async throws {
        categories.removeAll()
    }
}
