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
        var label: String {
            switch self {
                case .overview:
                    "Overview"
                case .contact:
                    "Contact"
            }
        }
    }
    
    var showingTagsSelector = false
    var selectedMenu: MenuItem = .overview
    var openURLAlert: OpenURLAlert? = nil
    var showingNavigationDialog: Bool = false
    var phoneScale: CGFloat = 1
    var urlScale: CGFloat = 1
    
    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
    }
    
    // MARK: Navigation
    func pushPlaceEditView(placeId: String) {
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
}
