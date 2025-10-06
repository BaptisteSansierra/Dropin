//
//  PlaceRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import SwiftData

public final class PlaceRepositoryImpl: PlaceRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
        
    func create(_ place: PlaceEntity) async throws {
        let sdPlace = PlaceMapper.toData(place)
        modelContext.insert(sdPlace)
        //sdPlace.save()
        try modelContext.save()
    }
    
    func delete(_ place: PlaceEntity) async throws {
        throw AppError.notImplemented
    }
    
    func getAll() async throws -> [PlaceEntity] {
        let descriptor = FetchDescriptor<SDPlace>()
        let sdPlaces = try modelContext.fetch(descriptor)
        return sdPlaces.map { PlaceMapper.toDomain($0) }
    }
}

