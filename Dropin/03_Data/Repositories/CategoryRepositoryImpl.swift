//
//  CategoryRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation
import SwiftData

public final class CategoryRepositoryImpl: CategoryRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: repository protocol methods
    func exists(_ category: Category) async throws -> Bool {
        do {
            _ = try await retrieveCategory(domainCategory: category)
            return true
        } catch DataError.duplicate(_) {
            return true
        } catch DataError.notFound(_) {
            return false
        }
    }

    func create(_ category: Category) async throws {
        let sdCategory = CategoryMapper.toData(category)
        modelContext.insert(sdCategory)
        try modelContext.save()
    }
    
    /* hard delete not used
    func delete(_ category: Category) async throws {
        let model = try await retrieveCategory(domainCategory: category)
        modelContext.delete(model)
        try modelContext.save()
    }
     */
    
    func update(_ category: Category) async throws {
        let model = try await retrieveCategory(domainCategory: category)
        model.name = category.name
        model.icon = category.icon
        model.color = category.color
        model.deletedAt = category.deletedAt
        model.updatedAt = category.updatedAt
        try modelContext.save()
    }
    
    func fetch() async throws -> [Category] {
        // Fetching do not ignore soft deleted objects (deletedAt) as swift UI may still rely on one of them
        let predicate: Predicate<CategoryRecord>? = nil
        let desc = FetchDescriptor<CategoryRecord>(predicate: predicate,
                                            sortBy: [SortDescriptor(\CategoryRecord.name),
                                                     SortDescriptor(\CategoryRecord.createdAt)])
        let sdCategories = try modelContext.fetch(desc)
        return sdCategories.map { CategoryMapper.toDomain($0) }
    }

    func fetchWithPlaceCount() async throws -> [(Category, Int)] {
        let predicate: Predicate<CategoryRecord>? = nil
        let desc = FetchDescriptor<CategoryRecord>(predicate: predicate,
                                            sortBy: [SortDescriptor(\CategoryRecord.name),
                                                     SortDescriptor(\CategoryRecord.createdAt)])
        let sdCategories = try modelContext.fetch(desc)
        return sdCategories.map { (CategoryMapper.toDomain($0), $0.places.count) }
    }

    func fetch(_ id: UUID) async throws -> Category {
        let sdCategory = try await retrieveCategory(categoryId: id)
        return CategoryMapper.toDomain(sdCategory)
    }
    
    func upsert(_ category: Category, shouldSave: Bool) async throws {
        let descriptor = FetchDescriptor<CategoryRecord>(predicate: #Predicate { $0.identifier == category.id })
        if let existing = try modelContext.fetch(descriptor).first {
            // Update
            existing.name      = category.name
            existing.color     = category.color
            existing.icon      = category.icon
            existing.updatedAt = category.updatedAt
            existing.deletedAt = category.deletedAt
        } else if category.deletedAt == nil {
            // Insert
            let sdCategory = CategoryMapper.toData(category)
            modelContext.insert(sdCategory)
        } else {
            // Tombstone for a category we never had locally — nothing to do.
            return
        }
        if shouldSave {
            try modelContext.save()
        }
    }
    
    func clearTable() async throws {
        try modelContext.delete(model: CategoryRecord.self)
        try modelContext.save()
    }
    
    // MARK: private methods
    private func retrieveCategory(domainCategory: Category) async throws -> CategoryRecord {
        let categoryId = domainCategory.id
        return try await retrieveCategory(categoryId: categoryId)
    }
    
    private func retrieveCategory(categoryId: UUID) async throws -> CategoryRecord {
        let predicate = #Predicate<CategoryRecord> { $0.identifier == categoryId }
        let descriptor = FetchDescriptor<CategoryRecord>(predicate: predicate)
        let sdCategories = try modelContext.fetch(descriptor)
        guard let result = sdCategories.first else {
            throw DataError.notFound(msg: "couldn't find CategoryRecord with id \(categoryId)")
        }
        guard sdCategories.count < 2 else {
            throw DataError.duplicate(msg: "found \(sdCategories.count) CategoryRecords with id \(categoryId)")
        }
        return result
    }
}
