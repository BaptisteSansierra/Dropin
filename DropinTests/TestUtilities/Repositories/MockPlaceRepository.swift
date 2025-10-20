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
    
    func getAll() async throws -> [PlaceEntity] {
        return places
    }
    
    func create(_ place: PlaceEntity) async throws {
        places.append(place)
    }
    
    func delete(_ place: PlaceEntity) async throws {
        guard let index = places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("shouldn't be reached, protected by UseCase")
        }
        print("Remove place at index \(index)")
        places.remove(at: index)
        //places.removeAll { $0.id == place.id }
    }
    
    func update(_ place: PlaceEntity) async throws {
    }
}
