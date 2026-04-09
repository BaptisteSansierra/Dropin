//
//  MockPlaceRepository.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

@MainActor
final class MockPlaceRepository: PlaceRepository {

    private var places: [PlaceEntity]

    init(initialPlaces: [PlaceEntity] = []) {
        self.places = initialPlaces
    }
    
    func exists(_ place: Dropin.PlaceEntity) async throws -> Bool {
        if let _ = places.first(where: { $0.id == place.id }) {
            return true
        }
        return false
    }
    
    func fetch(_ id: UUID) async throws -> Dropin.PlaceEntity {
        guard let g = places.first(where: { $0.id == id }) else {
            throw DataError.notFound(msg: "not found")
        }
        return g
    }
    
    func fetch() async throws -> [Dropin.PlaceEntity] {
        return try await fetch(nil)
    }

    func fetch(_ filter: Dropin.PlaceFilter?) async throws -> [Dropin.PlaceEntity] {
        guard let filter = filter, filter.isActive else {
            // no filtering
            return places
        }
        return places.filter { filter.matches($0) }
    }
    
    func create(_ place: PlaceEntity) async throws {
        places.append(place)
    }
    
    func delete(_ place: PlaceEntity) async throws {
        guard let index = places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        Log.info("Remove place at index \(index)")
        places.remove(at: index)
        //places.removeAll { $0.id == place.id }
    }
    
    func update(_ place: PlaceEntity) async throws {
    }
}
