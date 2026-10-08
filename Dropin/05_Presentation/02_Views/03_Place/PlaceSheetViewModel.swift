//
//  PlaceSheetViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/2/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation
import MapKit

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
    var thumbnails: [(id: UUID, state: ImageLoadState)] = []
    var selectedImageIndex: Int? = nil
    var isSharing: Bool = false
    var shareURL: IdentifiableURL? = nil
    var shareMessage: String = ""
    var shareSubject: String = ""
    var shareErrorMsg: String? = nil

    var resolvedMapItem: MKMapItem?
    var presentedMapItem: MKMapItem?
    var presentedPOIError: ApplePOIError?
    // Apple POI fetched data
    var applePhoneNumber: String?
    var appleURL: URL?
    var applePOIError: ApplePOIError?
    var applePOILoading = false

    @ObservationIgnored private var coordinator: any PlaceNavigationCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var shareService: any ShareServiceProtocol
    @ObservationIgnored private var getPlaceThumbnails: GetPlaceThumbnails
    @ObservationIgnored private var getPlaceImage: GetPlaceImage
    @ObservationIgnored private let markPlacePOINotFound: MarkPlacePOINotFound
    @ObservationIgnored private let applePOIService: any ApplePOIServiceProtocol
    
    init(_ appContainer: AppContainer,
         coordinator: any PlaceNavigationCoordinator,
         locationManager: LocationManager,
         shareService: any ShareServiceProtocol,
         getPlaceThumbnails: GetPlaceThumbnails,
         getPlaceImage: GetPlaceImage,
         markPlacePOINotFound: MarkPlacePOINotFound,
         applePOIService: any ApplePOIServiceProtocol) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.shareService = shareService
        self.getPlaceThumbnails = getPlaceThumbnails
        self.getPlaceImage = getPlaceImage
        self.markPlacePOINotFound = markPlacePOINotFound
        self.applePOIService = applePOIService
    }
    
    // MARK: Navigation
    func pushPlaceEditView(placeRef: PlaceUIModelRef) {
        coordinator.pushPlaceEditView(placeRef: placeRef)
    }
    
    // MARK: - callbacks and co
    func call(place: PlaceUIModel) {
        var phone = place.phone.first
        if phone == nil {
            phone = applePhoneContactItem(place)
        }
        guard let phone = phone else { return }
        do {
            try URLOpener.openURL(contactItem: phone)
        } catch {
            guard let error = error as? URLOpenerError else {
                return
            }
            openURLAlert = URLOpener.alertContent(error)
        }
    }
    
    func openWebLink(place: PlaceUIModel) {
        var url = place.url.first
        if url == nil {
            url = appleUrlContactItem(place)
        }
        guard let url = url else { return }
        do {
            try URLOpener.openURL(contactItem: url)
        } catch {
            guard let error = error as? URLOpenerError else {
                return
            }
            openURLAlert = URLOpener.alertContent(error)
        }
    }
    
    func routeThrowGoogle(place: PlaceUIModel) {
        //guard let url = URL(string: "comgooglemaps://?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"comgooglemaps://?daddr=\(place.address ?? "")") else { return }
        UIApplication.shared.open(url)
    }
    
    func routeThrowApple(place: PlaceUIModel) {
        //guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.address ?? "")") else { return }
        UIApplication.shared.open(url)
    }
    
    func routeThrowWaze(place: PlaceUIModel) {
        guard let url = URL(string: "https://www.waze.com/ul?ll=\(place.coordinates.latitude),\(place.coordinates.longitude)&navigate=yes") else { return }
        //guard let url = URL(string:"https://www.waze.com/ul?ll=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }
    
    func share(place: PlaceUIModel) async {
        shareErrorMsg = nil
        isSharing = true
        defer { isSharing = false }
        do {
            let url = try await shareService.shareURL(placeId: place.id)
            let senderName = appContainer.currentDisplayName?.isEmpty == false
                ? appContainer.currentDisplayName!
                : String(localized: "place_sheet.share.sender_fallback")
            shareMessage = String(format: NSLocalizedString("place_sheet.share.message", comment: ""), senderName)
            shareSubject = String(format: NSLocalizedString("place_sheet.share.email_subject", comment: ""), senderName, place.name)
            shareURL = IdentifiableURL(url: url)
        } catch {
            Log.error("PlaceSheetViewModel: share failed for place \(place.id): \(error)")
            if let urlError =  error as? URLError {
                switch urlError.code {
                    case .notConnectedToInternet:
                        shareErrorMsg = "place_sheet.share.error.connection"
                    default:
                        // shareErrorMsg is wrapped in LocalizedStringKey(_:) by the view, which needs
                        // the literal catalog key "place_sheet.share.error.url.%d" (with the code substituted via %d)
                        shareErrorMsg = String(format: NSLocalizedString("place_sheet.share.error.url.%d", comment: ""), urlError.code.rawValue)
                }
            } else {
                shareErrorMsg = "place_sheet.share.error"
            }
        }
    }
    
    func copyAddressToClipboard(place: PlaceUIModel) {
        guard let address = place.address else { return }
        UIPasteboard.general.string = address
    }
    
    func copyCoordinatesToClipboard(place: PlaceUIModel) {
        UIPasteboard.general.string = "\(place.coordinates.latitude), \(place.coordinates.longitude)"
    }
    
    func distanceStringTo(_ coords: CLLocationCoordinate2D) -> String? {
        return locationManager.distanceStringTo(coords)
    }
    
    func loadThumbnails(placeId: UUID) {
        Task {
            do {
                let initial = try await getPlaceThumbnails(placeId: placeId)
                thumbnails = initial
                for entry in initial where entry.state == .downloading {
                    Task { [weak self] in
                        guard let self else { return }
                        let final = await self.getPlaceThumbnails.awaitThumbnail(imageId: entry.id, placeId: placeId)
                        if let idx = self.thumbnails.firstIndex(where: { $0.id == entry.id }) {
                            self.thumbnails[idx] = (entry.id, final)
                        }
                    }
                }
            } catch {
                Log.error("Failed to load thumbnails for place \(placeId): \(error)")
            }
        }
    }
    
    func getFullImage(id: UUID, placeId: UUID) async -> ImageLoadState {
        await getPlaceImage(id: id, placeId: placeId)
    }
    
    func applePhoneContactItem(_ place: PlaceUIModel) -> ContactItem? {
        guard let applePhone = applePhoneNumber else { return nil }
        let label = String(localized: String.LocalizationValue("common.from_apple_maps"))
        return ContactItem(value: applePhone,
                           label: ContactLabel(kind: .phone,
                                               label: .custom(label)))
    }
    
    func appleUrlContactItem(_ place: PlaceUIModel) -> ContactItem? {
        guard let appleUrl = appleURL else { return nil }
        let label = String(localized: String.LocalizationValue("common.from_apple_maps"))
        return ContactItem(value: appleUrl.absoluteString,
                           label: ContactLabel(kind: .url,
                                               label: .custom(label)))
    }
    
    func fetchAppleDataIfNeeded(for place: PlaceUIModel) async {
        guard let appleId = place.applePlaceID else { return }
        applePOILoading = true
        applePOIError = nil
        defer {
            applePOILoading = false
        }
        do {
            let mapItem = try await applePOIService.details(for: appleId)
            resolvedMapItem = mapItem
            applePhoneNumber = mapItem.phoneNumber
            appleURL = mapItem.url
        } catch let error as ApplePOIError {
            applePOIError = error
            if error == .notFound {
                markPOINotFound(place)
            }
        } catch {
            applePOIError = ApplePOIError.unknown(error)
        }
    }
    
    private func markPOINotFound(_ place: PlaceUIModel) {
        // Store the appleNotFoundAt value without applying the possible edits on current place
        // by using the MarkPlacePOINotFound use case
        guard place.appleNotFoundAt == nil else {
            // This place was already marked previously, we want to keep the date of the first 'not found' occurence
            return
        }
        let notFoundAt = Date()
        place.appleNotFoundAt = notFoundAt
        Task {
            do {
                try await markPlacePOINotFound(uuid: place.id, date: notFoundAt)
            } catch {
                // This can be ignored, no useful data to show to the user here
            }
        }
    }
}
