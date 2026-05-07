//
//  PlaceSheetViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/2/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceSheetViewModel {
    
    enum MenuItem: Int, CaseIterable {
        case overview = 0
        case contact = 1
        case images = 2
        var label: String {
            switch self {
                case .overview:
                    "Overview"
                case .contact:
                    "Contact"
                case .images:
                    "Photos"
            }
        }
    }

    var showingTagsSelector = false
    var selectedMenu: MenuItem = .overview
    var openURLAlert: OpenURLAlert? = nil
    var showingNavigationDialog: Bool = false
    var phoneScale: CGFloat = 1
    var urlScale: CGFloat = 1
    var thumbnails: [(id: UUID, thumbnail: Data)] = []
    var selectedImageIndex: Int? = nil

    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var getPlaceThumbnails: GetPlaceThumbnails
    @ObservationIgnored private var getPlaceImage: GetPlaceImage

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager,
         getPlaceThumbnails: GetPlaceThumbnails,
         getPlaceImage: GetPlaceImage) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.getPlaceThumbnails = getPlaceThumbnails
        self.getPlaceImage = getPlaceImage
    }
    
    // MARK: Navigation
    func pushPlaceEditView(placeId: UUID) {
        coordinator.pushPlaceEditView(placeId: placeId)
    }
    
    // MARK: - callbacks and co
    func call(place: PlaceUI) {
        guard let phone = place.phone.first else { return }
        do {
            try URLOpener.openURL(contactItem: phone)
        } catch {
            guard let error = error as? URLOpenerError else {
                return
            }
            openURLAlert = URLOpener.alertContent(error)
        }
    }
    
    func openWebLink(place: PlaceUI) {
        guard let url = place.url.first else { return }
        do {
            try URLOpener.openURL(contactItem: url)
        } catch {
            guard let error = error as? URLOpenerError else {
                return
            }
            openURLAlert = URLOpener.alertContent(error)
        }
    }
    
    func routeThrowGoogle(place: PlaceUI) {
        //guard let url = URL(string: "comgooglemaps://?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"comgooglemaps://?daddr=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }
    
    func routeThrowApple(place: PlaceUI) {
        //guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }
    
    func routeThrowWaze(place: PlaceUI) {
        guard let url = URL(string: "https://www.waze.com/ul?ll=\(place.coordinates.latitude)-\(place.coordinates.longitude)&navigate=yes") else { return }
        //guard let url = URL(string:"https://www.waze.com/ul?ll=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }
    
    func copyAddressToClipboard(place: PlaceUI) {
        UIPasteboard.general.string = place.address
    }
    
    func copyCoordinatesToClipboard(place: PlaceUI) {
        UIPasteboard.general.string = "\(place.coordinates.latitude), \(place.coordinates.longitude)"
    }
    
    func distanceStringTo(_ coords: CLLocationCoordinate2D) -> String? {
        return locationManager.distanceStringTo(coords)
    }

    func loadThumbnails(placeId: UUID) {
        Task {
            do {
                thumbnails = try await getPlaceThumbnails(placeId: placeId)
            } catch {
                Log.error("Failed to load thumbnails for place \(placeId): \(error)")
            }
        }
    }

    func getFullImage(id: UUID) async -> Data? {
        do {
            return try await getPlaceImage(id: id)
        } catch {
            Log.error("Failed to load full image \(id): \(error)")
            return nil
        }
    }
}
