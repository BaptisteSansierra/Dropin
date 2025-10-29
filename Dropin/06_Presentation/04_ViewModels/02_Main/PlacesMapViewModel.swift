//
//  PlacesMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

struct PlaceID: Identifiable, Equatable {
    let id: String
}

struct Bucket {
    let origin: CLLocationCoordinate2D
    let span: MKCoordinateSpan
    let id: String
    init(region: MKCoordinateRegion) {
        self.origin = CLLocationCoordinate2D(latitude: region.center.latitude - region.span.latitudeDelta * 0.5,
                                             longitude: region.center.longitude -  region.span.longitudeDelta * 0.5)
        self.span = region.span
        self.id = UUID().uuidString
    }
}


@MainActor
@Observable class PlacesMapViewModel {
    
    private enum CreationMode {
        case coords
        case undefined
    }

    // MARK: Properties
    //var places: [PlaceUI] = [PlaceUI]()
    var tmpPlace: PlaceUI? = nil   // Used for creating a new place
    /// `selectedPlaceId` is defined when a place annotation is selected on the map, toggle the corresponding sheet
    var selectedPlaceId: PlaceID? {
        didSet {
//            guard let selectedPlaceId = selectedPlaceId else { return }
//            if places.firstIndex(where: { $0.id == selectedPlaceId.id }) == nil {
//                assertionFailure("no place found related to selectedPlaceId: \(selectedPlaceId)")
//                self.selectedPlaceId = nil
//            }
        }
    }
    var selectedCluster: MapDisplayClusterItem?
    
    var mapItems: [MapDisplayItem] = [MapDisplayItem]()
    var visiblePlaces = [PlaceUI]()
    var clusteringEnabled = true
    
    var buckets = [Bucket]()
    var debugDisplayBuckets = false

    
//    var mapPlaceItems: [MapDisplayPlaceItem] = [MapDisplayPlaceItem]()
//    var mapClusterItems: [MapDisplayClusterItem] = [MapDisplayClusterItem]()

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let getPlaces: GetPlaces
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private var creationMode: CreationMode = .undefined  // TODO: to be used ?
    //@ObservationIgnored private let deletePlace: DeletePlace
    
    init(_ appContainer: AppContainer, getPlaces: GetPlaces, createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.getPlaces = getPlaces
        self.createPlace = createPlace
    }
    
    func preparePlaceFromCoords(coords: CLLocationCoordinate2D) -> PlaceUI {
        creationMode = .coords
        let createdPlace = PlaceUI(coordinates: coords)
        tmpPlace = createdPlace
        return createdPlace
    }
    
    func discardCreation() {
        reset()
    }


/*

 TODO: to be improved, make caching independant from camera
 
 // Compute grid once for ALL items, regardless of camera
 private var globalGridClusters: [GridCell: [Place]] {
     // Cache this! Only recompute when data changes, not camera
     let cellSize = 0.1 // degrees, to be adjusted based on the needs
     
     var grid: [GridCell: [Place]] = [:]
     for place in allPlaces {
         let cell = GridCell(
             lat: Int(place.coordinate.latitude / cellSize),
             lon: Int(place.coordinate.longitude / cellSize)
         )
         grid[cell, default: []].append(place)
     }
     return grid
 }

 // Then just filter visible cells based on camera
 func visibleClusters(for region: MKCoordinateRegion) -> [Cluster] {
     let visibleCells = cellsInRegion(region)
     return visibleCells.compactMap { globalGridClusters[$0] }
         .map { Cluster(places: $0) }
 }
 
 
 */
    func gridBasedClustering(_ places: [PlaceUI],
                             center: CLLocationCoordinate2D,
                             span: MKCoordinateSpan) {
        
        // Clear
        mapItems.removeAll()
        visiblePlaces.removeAll()
        buckets.removeAll()

        guard places.count > 0 else { return }

        // TODO: optimize getting places by coords
        /*
         Simple binning / grid bucketing should be enough at the moment :
             Divide the map into a fixed grid (say, 0.1° × 0.1° cells).
             let latKey = Int(place.latitude * 10)
             let lonKey = Int(place.longitude * 10)
             let key = "\(latKey)_\(lonKey)"
             buckets[key, default: []].append(place)

         For many points (> 10 000), should use spatial trees (QuadTree / KD-Tree)
         */
        
        // filter places inside current rectangle
        let maxLat = center.latitude + span.latitudeDelta * 0.5
        let minLat = center.latitude - span.latitudeDelta * 0.5
        let maxLong = center.longitude + span.longitudeDelta * 0.5
        let minLong = center.longitude - span.longitudeDelta * 0.5
        
        
        visiblePlaces = places.filter { place in
            // Ignore deleted places
            guard !place.databaseDeleted else { return false }
            // Filter places in visible region
            return place.coordinates.isInside(minLatitude: minLat, maxLatitude: maxLat,
                                              minLongitude: minLong, maxLongitude: maxLong)
        }
        
        guard clusteringEnabled else { return }
        
        
        // clustering
        let hDivisions = 6    // number of longitude divisions
        let vDivisions = 12    // number of latitude divisions
        let longitudeStart = center.longitude - span.longitudeDelta * 0.5
        let latitudeStart = center.latitude - span.latitudeDelta * 0.5
        let longitudeStep = span.longitudeDelta / Double(hDivisions)
        let latitudeStep = span.latitudeDelta / Double(vDivisions)

        let longitudeDivisions = Array(0..<hDivisions).map({ longitudeStart + Double($0) * longitudeStep })
        let latitudeDivisions = Array(0..<vDivisions).map({ latitudeStart + Double($0) * latitudeStep })
        
        #if DEBUG
        if debugDisplayBuckets {
            for i in 0..<hDivisions { // longitude
                for j in 0..<vDivisions {  // latitude
                    let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitudeDivisions[j] + latitudeStep * 0.5,
                                                                                   longitude: longitudeDivisions[i] + longitudeStep * 0.5),
                                                    span: MKCoordinateSpan(latitudeDelta: latitudeStep, longitudeDelta: longitudeStep))
                    buckets.append(Bucket(region: region))
                }
            }
        }
        #endif
        
        var remainingPlaces = visiblePlaces

        // TODO: check if places array is the same as last iteration before clustering again + zoom did not significantly change
        
        var log = ""
        for i in 0..<hDivisions { // longitude

            if remainingPlaces.count == 0 {
                break
            }
            log = "\(log)\(i).\t"
            for j in 0..<vDivisions {  // latitude
                
                // Get places for bucket(i,j)
                let minBucketLong = longitudeDivisions[i]
                let minBucketLat = latitudeDivisions[j]
                
                var bucketPlaces = [PlaceUI]()
                var nextRemainingPlaces = remainingPlaces
                for k in 0..<remainingPlaces.count {
                    let place = remainingPlaces[k]

                    if place.coordinates.isInside(minLatitude: minBucketLat,
                                                  maxLatitude: minBucketLat + latitudeStep,
                                                  minLongitude: minBucketLong,
                                                  maxLongitude: minBucketLong + longitudeStep) {
                        bucketPlaces.append(remainingPlaces[k])
                        nextRemainingPlaces.removeAll { place.id == $0.id }
                    }
                }
                
                if bucketPlaces.count == 1 {
                    mapItems.append(MapDisplayPlaceItem(place: bucketPlaces.first!))
                } else if bucketPlaces.count > 1 {
                    mapItems.append(MapDisplayClusterItem(places: bucketPlaces))
                }

                log = "\(log) \(bucketPlaces.count)"
                if j == vDivisions - 1 {
                    log = "\(log)\n"
                }

                // Compute remaining places
                remainingPlaces = nextRemainingPlaces
                if remainingPlaces.count == 0 {
                    break
                }
            }
        }
//        print("----- BUCKETS -----")
//        print(log)
//        print("----- ------- -----")
//        print("Remaining places: \(remainingPlaces.count)")
    }
    
    // MARK: - UI child
    func createCreatePlacesView() -> CreatePlaceView {
        guard let tmpPlace = tmpPlace else {
            fatalError("temporary place undefined")
        }
        return appContainer.createCreatePlaceView(place: tmpPlace)
    }
        
    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        return appContainer.createPlaceDetailsView(place: place, editMode: editMode)
    }

    func createPlaceDetailsSheetView(place: Binding<PlaceUI>) -> PlaceDetailsSheetView {
        return appContainer.createPlaceDetailsSheetView(place: place)
    }

    // MARK: - Use cases
    func loadPlaces() async throws -> [PlaceUI] {
        let domainPlaces = try await getPlaces.execute()
        let places = domainPlaces.map { PlaceMapper.toUI($0) }
        // check selectedPlaceId is nil or valid after loading places
        if let selectedPlaceId = selectedPlaceId {
            if places.firstIndex(where: { $0.id == selectedPlaceId.id }) == nil {
                self.selectedPlaceId = nil
            }
        }
        return places
    }

    // MARK: - private
    private func reset() {
        tmpPlace = nil
        //buildingPlace = false
        creationMode = .undefined
    }
}
