//
//  GroupDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupDetailsViewModel {

    var loadingPlaces = false
    var places: [PlaceUI] = []

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var updateGroup: UpdateGroup
    @ObservationIgnored private var deleteGroup: DeleteGroup
    @ObservationIgnored private var fetchGroupPlaces: FetchGroupPlaces
    @ObservationIgnored private var updatePlace: UpdatePlace

    init(_ appContainer: AppContainer,
         locationManager: LocationManager,
         updateGroup: UpdateGroup,
         deleteGroup: DeleteGroup,
         fetchGroupPlaces: FetchGroupPlaces,  // TODO : useless ?
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.locationManager = locationManager
        self.updateGroup = updateGroup
        self.deleteGroup = deleteGroup
        self.fetchGroupPlaces = fetchGroupPlaces
        self.updatePlace = updatePlace
    }
    
    // MARK: use cases
    func updateGroup(_ group: GroupUI) async throws {
        try await updateGroup(GroupMapper.toDomain(group))
    }
    
    func deleteGroup(_ group: GroupUI) async throws {
        try await deleteGroup(GroupMapper.toDomain(group))
        if group.deletedAt == nil {
            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
            group.deletedAt = Date()
        }
    }

    func fetchPlace(_ groupId: UUID) async throws {
        loadingPlaces = true
        places = try await fetchGroupPlaces(groupId)
            .map({ PlaceMapper.toUI($0) })
        loadingPlaces = false
    }

    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace(PlaceMapper.toDomain(place))
    }
}
