//
//  TagDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/25.
//

import SwiftUI

@MainActor
@Observable class TagDetailsViewModel {
    
    var loadingPlaces = false
    var places: [PlaceUI] = []
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var updateTag: UpdateTag
    @ObservationIgnored private var deleteTag: DeleteTag
    @ObservationIgnored private var fetchTagPlaces: FetchTagPlaces
    @ObservationIgnored private var updatePlace: UpdatePlace
    
    init(_ appContainer: AppContainer,
         locationManager: LocationManager,
         updateTag: UpdateTag,
         deleteTag: DeleteTag,
         fetchTagPlaces: FetchTagPlaces,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.locationManager = locationManager
        self.updateTag = updateTag
        self.deleteTag = deleteTag
        self.fetchTagPlaces = fetchTagPlaces
        self.updatePlace = updatePlace
    }
    
    // MARK: use cases
    func updateTag(_ tag: TagUI) async throws {
        try await updateTag.execute(TagMapper.toDomain(tag))
    }
    
    func deleteTag(_ tag: TagUI) async throws {
        try await deleteTag.execute(TagMapper.toDomain(tag))
        if tag.deletedAt == nil {
            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
            tag.deletedAt = Date()
        }
    }
    
    func fetchPlace(_ tagId: UUID) async throws {
        loadingPlaces = true
        places = try await fetchTagPlaces.execute(tagId)
            .map({ PlaceMapper.toUI($0) })
        loadingPlaces = false
        print("\(places.count) PLACES LOADED")
    }

    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace.execute(PlaceMapper.toDomain(place))
    }
}
