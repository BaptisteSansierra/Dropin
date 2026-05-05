//
//  DeleteLibrary.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
struct DeleteLibrary {
    private let placeRepository: PlaceRepository
    private let groupRepository: GroupRepository
    private let tagRepository: TagRepository

    init(placeRepository: PlaceRepository, groupRepository: GroupRepository, tagRepository: TagRepository) {
        self.placeRepository = placeRepository
        self.groupRepository = groupRepository
        self.tagRepository = tagRepository
    }

    func callAsFunction() async throws {
        for place in try await placeRepository.fetch() {
            try await placeRepository.delete(place)
        }
        for group in try await groupRepository.fetch() {
            try await groupRepository.delete(group)
        }
        for tag in try await tagRepository.fetch() {
            try await tagRepository.delete(tag)
        }
    }
}
