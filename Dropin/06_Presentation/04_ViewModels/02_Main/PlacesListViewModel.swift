//
//  PlacesListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable class PlacesListViewModel {
    
    enum SortMode: Int {
        case distance = 0
        case alphabetically = 1
        case creationDate = 2
    }

    // MARK: Properties
    var sortedPlaces: [PlaceUI] = []
    var groupedSortedPlaces: [String: [PlaceUI]] = [:] // places grouped by group (key=group identifier)
    var ungroupedSortedPlaces: [PlaceUI] = []
    var searchText = ""
    var grouped = false
    var sortMode: SortMode = .distance
    var loading: Bool = true

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let getPlaces: GetPlaces
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private let locationManager: LocationManager
    
    init(_ appContainer: AppContainer, locationManager: LocationManager, getPlaces: GetPlaces, createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.getPlaces = getPlaces
        self.createPlace = createPlace
        self.locationManager = locationManager
    }
    
    func updateSorting(_ places: [PlaceUI]) {
        loading = true
        defer { loading = false }
        sortedPlaces.removeAll()
        groupedSortedPlaces.removeAll()
        ungroupedSortedPlaces.removeAll()
        guard grouped else {
            sortPlaces(places)
            return
        }
        sortGroupedPlaces(places)
    }

    private func sortGroupedPlaces(_ places: [PlaceUI]) {
        groupedSortedPlaces.removeAll()
        ungroupedSortedPlaces.removeAll()
        for place in places {
            guard let group = place.group else {
                ungroupedSortedPlaces.append(place)
                continue
            }
            if groupedSortedPlaces[group.id] != nil {
                groupedSortedPlaces[group.id]?.append(place)
            } else {
                groupedSortedPlaces[group.id] = [place]
            }
        }
        // Sort all arrays
        ungroupedSortedPlaces = sortedPlaces(ungroupedSortedPlaces)
        let sortedKeys = groupedSortedPlaces.keys.sorted()
        for k in sortedKeys {
            guard let groupPlaces = groupedSortedPlaces[k] else {
                groupedSortedPlaces.removeValue(forKey: k)
                continue
            }
            groupedSortedPlaces[k] = sortedPlaces(groupPlaces)
        }
    }
    
    private func sortPlaces(_ places: [PlaceUI]) {
        sortedPlaces = sortedPlaces(places)
    }
    
    private func sortedPlaces(_ places: [PlaceUI]) -> [PlaceUI] {
        switch sortMode {
            case .alphabetically:
                return places.sorted { p1, p2 in
                    if p1.name.compare(p2.name) == .orderedSame {
                        return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                    }
                    return p1.name.compare(p2.name) == .orderedAscending
                }
            case .creationDate:
                return places.sorted { p1, p2 in
                    return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                }
            case .distance:
                return places.sorted { p1, p2 in
                    guard let d1 = locationManager.distanceTo(p1.coordinates),
                          let d2 = locationManager.distanceTo(p2.coordinates) else {
                        if p1.name.compare(p2.name) == .orderedSame {
                            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                        }
                        return p1.name.compare(p2.name) == .orderedAscending
                    }
                    return d1 < d2
                }
        }
    }

    // MARK: - UI child
    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        return appContainer.createPlaceDetailsView(place: place, editMode: editMode)
    }

    // MARK: - Use cases
    func loadPlaces() async throws -> [PlaceUI] {
        let domainPlaces = try await getPlaces.execute()
        return domainPlaces.map { PlaceMapper.toUI($0) }
    }

    // MARK: - private methods
}
