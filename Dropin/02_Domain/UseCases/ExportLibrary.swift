//
//  Export.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

//
//TODO :
//make all EntityModels let ? so they can be Sendable ??
//Can the be sendable in fact as they use ContactItems ?




/*
@MainActor
struct ExportLibrary {
    private let pRepository: PlaceRepository
    private let gRepository: GroupRepository
    private let tRepository: TagRepository

    init(pRepository: PlaceRepository, gRepository: GroupRepository, tRepository: TagRepository) {
        self.pRepository = pRepository
        self.gRepository = gRepository
        self.tRepository = tRepository
    }
    
    func execute() async throws -> ([PlaceEntity], [GroupEntity], [TagEntity]) {
        async let places = pRepository.fetch()
        async let groups = gRepository.fetch()
        async let tags = tRepository.fetch()
        return try await (places, groups, tags)
    }
}
*/
