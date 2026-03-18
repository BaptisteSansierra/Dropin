//
//  MapDataSource.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import SwiftUI
import MapKit
import ClusterMap

@MainActor
@Observable final class MapDataSource: ObservableObject {

    var mapSize: CGSize = .zero

    private var allAnnotations: [PlaceAnnotationModel] = []

    private(set) var annotations: [PlaceAnnotationModel] = []
    private(set) var clusters: [ClusterAnnotationModel] = []

    private let clusterManager: ClusterManager<PlaceAnnotationModel>
    private var currentRegion: MKCoordinateRegion = .zero

    init() {
        let config = ClusterManager<PlaceAnnotationModel>.Configuration(
            maxZoomLevel: 30,
            minCountForClustering: 2,
            shouldRemoveInvisibleAnnotations: true,
            shouldDistributeAnnotationsOnSameCoordinate: true,
            distanceFromContestedLocation: 3,
            clusterPosition: .center)
        clusterManager = ClusterManager<PlaceAnnotationModel>(configuration: config)
    }

    func isEmpty() -> Bool {
        annotations.count == 0 && clusters.count == 0
    }

    func loadPlaces(_ places: [PlaceUI]) async {
        guard annotations.count == 0, clusters.count == 0 else {
            // Ensure it's called only once
            fatalError("Cannot double load places")
        }
        allAnnotations = places
            .filter({ $0.isActive })
            .map({ PlaceAnnotationModel(coordinates: $0.coordinates,
                                        placeId: $0.id) })
        await clusterManager.add(allAnnotations)
        await reloadAnnotations()
    }
    
    func updatePlaces(_ places: [PlaceUI]) async {
        // Remove places
        // Get all annotations not in places or with 'databaseDeleted' true
        let toBeRemoved = allAnnotations.filter { item in
            if let place = places.first(where: { $0.id == item.placeId }) {
                return !place.isActive
            }
            return true
        }
        allAnnotations.removeAll(where: { toBeRemoved.contains($0) })
        await clusterManager.remove(toBeRemoved)
        
        // Add places
        // Get all places not in annotations and not deleted
        let placesToBeAdded = places.filter { place in
            if let _ = allAnnotations.first(where: { $0.placeId == place.id }) {
                return false
            }
            return place.isActive
        }
        let toBeAdded = placesToBeAdded.map({ PlaceAnnotationModel(coordinates: $0.coordinates,
                                                               placeId: $0.id)})
        allAnnotations.append(contentsOf: toBeAdded)
        await clusterManager.add(toBeAdded)
    }

    func reloadAnnotations(region: MKCoordinateRegion) async {
        currentRegion = region
        await reloadAnnotations()
    }

    func reloadAnnotations() async {
        async let changes = clusterManager.reload(mapViewSize: mapSize, coordinateRegion: currentRegion)
        await applyChanges(changes)
    }
    
    @MainActor
    private func applyChanges(_ difference: ClusterManager<PlaceAnnotationModel>.Difference) {
        for removal in difference.removals {
            switch removal {
                case .annotation(let annotation):
                    annotations.removeAll { $0 == annotation }
                case .cluster(let clusterAnnotation):
                    clusters.removeAll { $0.id == clusterAnnotation.id }
            }
        }
        for insertion in difference.insertions {
            switch insertion {
                case .annotation(let newItem):
                    annotations.append(newItem)
                case .cluster(let newItem):
                    var span: MKCoordinateSpan {
                        let result = newItem.memberAnnotations.reduce(MKCoordinateSpan.zero) { partialResult, memberAnnotation in
                            let latDelta = 2 * abs(newItem.coordinate.latitude - memberAnnotation.coordinate.latitude)
                            let lonDelta = 2 * abs(newItem.coordinate.longitude - memberAnnotation.coordinate.longitude)
                            return MKCoordinateSpan(latitudeDelta: partialResult.latitudeDelta > latDelta ? partialResult.latitudeDelta : latDelta,
                                                    longitudeDelta: partialResult.longitudeDelta > lonDelta ? partialResult.longitudeDelta : lonDelta)
                        }
                        // Add a margin
                        return MKCoordinateSpan(latitudeDelta: result.latitudeDelta * 1.5,
                                                longitudeDelta: result.longitudeDelta * 1.5)
                    }
                    clusters.append(ClusterAnnotationModel(id: newItem.id,
                                                           coordinate: newItem.coordinate,
                                                           count: newItem.memberAnnotations.count,
                                                           span: span))
            }
        }
    }
}

