//
//  PlacesMKMapVCR.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/6/26.
//

import SwiftUI
import UIKit
import MapKit

typealias MapCameraUpdateHandler = (MKMapCamera,
                                    MKCoordinateRegion,
                                    MKMapRect) -> Void

@MainActor
struct PlacesMKMapVCR: UIViewControllerRepresentable {

    struct Configuration {
        enum LaunchPosition: Equatable {
            static func == (lhs: LaunchPosition, rhs: LaunchPosition) -> Bool {
                switch (lhs, rhs) {
                    case (.user, .user): return true
                    case (.region, .region): return true
                    case (.none, .none): return true
                    default: return false
                }
            }
            case user
            case region(region: MKCoordinateRegion)
            case none
        }
        
        var scrollEnabled = true
        var zoomEnabled = true
        var rotateEnabled = false
        //var clustering = true
        var showsUserLocation = true
        //var tracksUserAtLaunch = true
        var positionAtLaunch: LaunchPosition = .user
        //var hidesLabelsWhenZoomedOut = true

        static let interactive = Configuration()                 // main map
        static let preview = Configuration(scrollEnabled: false,
                                           zoomEnabled: false,
                                           showsUserLocation: false,
                                           positionAtLaunch: .region(region: .abbeyRoad
                                            .offset(lat: -0.001)))
        static let browse = Configuration(positionAtLaunch: .none)  // group/tag map ??
    }
    
    struct InteractionStatus {
        let selectionEnabled: Bool
        let longPressEnabled: Bool
        static let none = InteractionStatus(selectionEnabled: false, longPressEnabled: false)
        static let all = InteractionStatus(selectionEnabled: true, longPressEnabled: true)
    }
    
    @Environment(AppSettings.self) private var appSettings

    @Binding private var selectedPlaceId: UUID?

    private let config: Configuration
    private let mapController: MapController
    private let places: [PlaceUI]
    private let draftCoordinate: CLLocationCoordinate2D?
    private let bottomInset: CGFloat
    private let mapReloadGen: Int
    private let onLongPress: ((CLLocationCoordinate2D) -> Void)?
    private let onMapCameraUpdate: MapCameraUpdateHandler?
    private let interactionStatus: (() -> InteractionStatus)
    private let isActiveTab: Bool

    // MARK: Init
    init(config: Configuration,
         mapController: MapController,
         places: [PlaceUI],
         draftCoordinate: CLLocationCoordinate2D? = nil,
         selectedPlaceId: Binding<UUID?>,
         onLongPress: ((CLLocationCoordinate2D) -> Void)? = nil,
         onMapCameraUpdate: MapCameraUpdateHandler? = nil,
         interactionStatus: @escaping (() -> InteractionStatus),
         mapReloadGen: Int = 0,
         bottomInset: CGFloat = 0,
         isActiveTab: Bool = true) {
        self.config = config
        self.mapController = mapController
        self.places = places
        self.draftCoordinate = draftCoordinate
        self._selectedPlaceId = selectedPlaceId
        //self.onPlaceSelected = onPlaceSelected
        self.onLongPress = onLongPress
        self.onMapCameraUpdate = onMapCameraUpdate
        self.interactionStatus = interactionStatus
        self.mapReloadGen = mapReloadGen
        self.bottomInset = bottomInset
        self.isActiveTab = isActiveTab
    }
    
    func makeUIViewController(context: Context) -> PlacesMKMapVC {
        let viewController = PlacesMKMapVC()
        viewController.coordinator = context.coordinator
        context.coordinator.mapView = viewController.mapView
        
        // Connect map controller
        mapController.connect(context.coordinator)
        
        // Gestures
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        context.coordinator.mapView!.addGestureRecognizer(longPress)
        
        return viewController
    }
        
    func updateUIViewController(_ viewController: PlacesMKMapVC, context: Context) {
        guard let mapView = context.coordinator.mapView else { assertionFailure(); return }
        
        // Update map controller connection
        mapController.connect(context.coordinator)

        // Set additional safe area insets
        let safeAreaInsets = UIEdgeInsets(top: 0,
                                          left: 0,
                                          bottom: bottomInset,
                                          right: 0)
        if viewController.additionalSafeAreaInsets != safeAreaInsets {
            viewController.additionalSafeAreaInsets = safeAreaInsets
        } else {
            //print("1 no-op safearea")
        }

        //
        // Map style
        //
        if mapStyleHasChanged(mapView,
                              satellite: appSettings.mapSettings.satellite,
                              hidePointsOfInterest: appSettings.mapSettings.hidePOI) {
            applyMapStyle(to: mapView,
                          satellite: appSettings.mapSettings.satellite,
                          hidePointsOfInterest: appSettings.mapSettings.hidePOI)
        } else {
            //print("2 no-op map style")
        }
        
        //
        // Check if settings were updated
        //
        var shouldUpdateAnnotation = false
        if context.coordinator.mapSettings != appSettings.mapSettings {
            let affectsAnns = appSettings.mapSettings.isDiffAffectsAnnotations(context.coordinator.mapSettings)
            context.coordinator.updateSettings(appSettings.mapSettings)
            if affectsAnns { shouldUpdateAnnotation = true }
        } else {
            //print("3 no-op map settings")
        }

        //
        // Update pendingCoordinate if needed (trigger center on new one)
        //
        if let draftCoordinate = draftCoordinate,
           context.coordinator.draftCoordinate != draftCoordinate {
            // Coordinator is not aligned, which means we have a new draft
            // > update coordinator and center on map
            context.coordinator.updateDraftCoordinate(draftCoordinate)
            updateDraftAnnotations(mapView)
        } else if let _ = draftCoordinate {
            // No-op: coordinator is aligned with VCR
            //print("4 no-op draft annotation")
        } else if context.coordinator.draftCoordinate != nil {
            // We need to reset coordinator, aka remove the draft annotation
            context.coordinator.resetDraftCoordinate()
            updateDraftAnnotations(mapView)
        }

        // Reload annotations (places were reloaded from )
        if context.coordinator.lastReloadGen != mapReloadGen || shouldUpdateAnnotation {
            context.coordinator.lastReloadGen = mapReloadGen
            reloadDotAnnotations(mapView)
            // Full wipe just tore down any promoted annotations too — reset the
            // bookkeeping so refreshPinSelection treats everyone as needing to be
            // re-added rather than skipping because the id set happens to match.
            context.coordinator.resetPromotedTracking()
            // Deferred a run-loop turn: mapView.annotations(in:) isn't guaranteed to
            // reflect annotations added earlier in this same call stack, so calling
            // refreshPinSelection synchronously here can race and see an empty
            // visible set — silently promoting nothing.
            DispatchQueue.main.async { [weak mapView] in
                guard let mapView else { return }
                context.coordinator.refreshPinSelection(mapView)
            }
        } else {
            //print("5 no-op reload annotation")
        }

        // Update annotations — only rebuild when the active place set actually changed
        let activeIds = Set(places.lazy.filter { $0.isActive }.map { $0.id })
        if activeIds != context.coordinator.lastActiveIds {
            context.coordinator.lastActiveIds = activeIds
            updateDotAnnotations(mapView)
            // Same deferral as above — avoids racing mapView.annotations(in:).
            DispatchQueue.main.async { [weak mapView] in
                guard let mapView else { return }
                context.coordinator.refreshPinSelection(mapView)
            }
        } else {
            //print("6 no-op update annotation")
        }

        //
        // Update selection
        //
        if isActiveTab, mapView.selectedAnnotations.count == 0, let selectedPlaceId {
            // Select (triggers didSelect → zoom+center) — only while this map is the visible tab.
            // Prefer the promoted (full pin) annotation if one exists; fall back to
            // the dot otherwise (e.g. clustering mode, or a place not currently
            // promoted) — both conform to MKPlaceAnnotationRepresentable.
            let match: MKAnnotation? = mapView.annotations
                .compactMap({ $0 as? MKPlacePromotedAnnotation })
                .first(where: { $0.id == selectedPlaceId })
                ?? mapView.annotations
                .compactMap({ $0 as? MKPlaceDotAnnotation })
                .first(where: { $0.id == selectedPlaceId })
            if let match {
                mapView.selectAnnotation(match, animated: true)
            }
        } else if mapView.selectedAnnotations.count > 0 && selectedPlaceId == nil {
            // Deselect — harmless regardless of tab, no camera movement.
            mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
        } else {
            //print("7 no-op selected annotation")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(config: config,
                    mapSettings: appSettings.mapSettings,
                    onPlaceSelected: { uuid in
                        selectedPlaceId = uuid
                    },
                    onLongPress: onLongPress,
                    onMapCameraUpdate: onMapCameraUpdate,
                    interactionStatus: interactionStatus)
    }
    
    // MARK: private methods
    private func mapStyleHasChanged(_ mapView: MKMapView, satellite: Bool, hidePointsOfInterest: Bool) -> Bool {
        if mapView.mapType == .standard && satellite {
            return true
        }
        if mapView.mapType == .hybrid && !satellite {
            return true
        }
        if let poiFilter = mapView.pointOfInterestFilter {
            if hidePointsOfInterest && poiFilter.includes(.airport) {
                return true
            }
            if !hidePointsOfInterest && !poiFilter.includes(.airport) {
                return true
            }
        } else {
            return true
        }
        return false
    }
    
    private func applyMapStyle(to mapView: MKMapView, satellite: Bool, hidePointsOfInterest: Bool) {
        // Map type
        mapView.mapType = satellite ? .hybrid : .standard
        
        // Points of interest filter
        if hidePointsOfInterest {
            mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
        } else {
            mapView.pointOfInterestFilter = .includingAll
        }
        // Traffic
        //mapView.showsTraffic = false
    }
    
    private func reloadDotAnnotations(_ mapView: MKMapView) {
        let latestAnnotations = places
            .filter { $0.isActive }
            .map { MKPlaceDotAnnotation(place: $0) }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(latestAnnotations)
    }
    
    private func updateDotAnnotations(_ mapView: MKMapView) {
        let activePlaces = places.filter { $0.isActive }
        let current = mapView.annotations.compactMap { $0 as? MKPlaceDotAnnotation }

        let newIds = Set(activePlaces.map { $0.id })
        let currentIds = Set(current.map { $0.id })

        // Remove legacy annotations
        let toRemove = current.filter { !newIds.contains($0.id) }
        mapView.removeAnnotations(toRemove)

        // Add new annotations
        let toAdd = activePlaces
            .filter { !currentIds.contains($0.id) }
            .map { MKPlaceDotAnnotation(place: $0) }
        mapView.addAnnotations(toAdd)
    }
    
    private func updateDraftAnnotations(_ mapView: MKMapView) {
        // Remove old pending coordinate if needed
        let draftAnnotations = mapView.annotations.compactMap { $0 as? MKDraftPlaceAnnotation }
        if draftAnnotations.count > 1 {
            assertionFailure("More than one draft annotation found...")
        }
        
        if let existing = draftAnnotations.first, let draftCoordinate {
            // Same annotation, new position, mutate in place so MapKit animates
            // it smoothly instead of tearing down and recreating the view.
            existing.coordinate = draftCoordinate
        } else {
            mapView.removeAnnotations(draftAnnotations)
            if let draftCoordinate {
                mapView.addAnnotation(MKDraftPlaceAnnotation(coordinate: draftCoordinate))
            }
        }
    }
    
    private func pendingAnnotation(_ mapView: MKMapView) -> MKDraftPlaceAnnotation? {
        let pendingAnnotations = mapView.annotations.compactMap { $0 as? MKDraftPlaceAnnotation }
        guard pendingAnnotations.count <= 1 else {
            assertionFailure("More than one pending annotation found...")
            mapView.removeAnnotations(pendingAnnotations)
            return nil
        }
        return pendingAnnotations.first
    }
}

// MARK: Coordinator
extension PlacesMKMapVCR {
    
    @MainActor
    class Coordinator: NSObject {
        
        fileprivate var config: Configuration
        fileprivate var annotationViewFactory: AnnotationViewFactory
        fileprivate var mapSettings: MapSettings
        
        private let onPlaceSelected: ((UUID) -> Void)
        private let onLongPress: ((CLLocationCoordinate2D) -> Void)?
        private let onMapCameraUpdate: MapCameraUpdateHandler?
        private let interactionStatus: (() -> InteractionStatus)
        private(set) var draftCoordinate: CLLocationCoordinate2D? = nil

        private var hasSnappedToUser = false

        var lastReloadGen: Int = 0
        weak var mapView: MKMapView?

        // Annotation update guard
        var lastActiveIds: Set<UUID> = []
        // Label visibility state
        private var labelsVisible: Bool = true
        // IDs currently backed by a live MKPlacePromotedAnnotation.
        private var promotedIds: Set<UUID> = []
        // Debounced declutter/pin-selection refresh — see scheduleDeclutterRefresh
        private var pendingDeclutterRefresh: DispatchWorkItem?
        
        // MARK: init
        init(config: Configuration,
             mapSettings: MapSettings,
             onPlaceSelected: @escaping ((UUID) -> Void),
             onLongPress: ((CLLocationCoordinate2D) -> Void)?,
             onMapCameraUpdate: MapCameraUpdateHandler?,
             interactionStatus: @escaping (() -> InteractionStatus) ) {
            self.config = config
            self.mapSettings = mapSettings
            self.annotationViewFactory = AnnotationViewFactory(mapSettings: mapSettings)
            self.onPlaceSelected = onPlaceSelected
            self.onLongPress = onLongPress
            self.onMapCameraUpdate = onMapCameraUpdate
            self.interactionStatus = interactionStatus
        }
        
        func updateSettings(_ mapSettings: MapSettings) {
            self.mapSettings = mapSettings
            self.annotationViewFactory = AnnotationViewFactory(mapSettings: mapSettings)
        }
        
        // MARK: - gestures
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard interactionStatus().longPressEnabled else { return }
            guard let onLongPress = onLongPress else { return }
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            onLongPress(coordinates)
        }
        
        func fitAll(animated: Bool) {
            guard let mapView else { return }
            // Dots are the canonical one-entry-per-place set (always present),
            // unlike promoted annotations which are only a subset.
            let placeAnnotations = mapView.annotations.compactMap { $0 as? MKPlaceDotAnnotation }
            guard !placeAnnotations.isEmpty else { return }
            mapView.showAnnotations(placeAnnotations, animated: animated)
        }
        
        func centerOn(coords: CLLocationCoordinate2D,
                      withSheetOffset: Bool,
                      animated: Bool = true) {
            guard let mapView = mapView else { return }
            centerOn(mapView,
                     coords: coords,
                     withSheetOffset: withSheetOffset,
                     animated: true)
        }
        
        func updateDraftCoordinate(_ coords: CLLocationCoordinate2D) {
            guard draftCoordinate != coords else { return }
            draftCoordinate = coords
            centerOn(coords: coords,
                     withSheetOffset: true,
                     animated: true)
        }
        
        func resetDraftCoordinate() {
            draftCoordinate = nil
        }

        // MARK: - debounced declutter/pin refresh

        /// `regionDidChangeAnimated` is not reliably "gesture ended" — Apple's docs
        /// note it can fire multiple times while a scrolling animation is still in
        /// progress. Running the declutter/pin-swap work directly off it caused both
        /// mid-gesture position decorrelation and dot/pin pop-in flicker. Debouncing
        /// off the continuous `mapViewDidChangeVisibleRegion` instead guarantees the
        /// work only runs once the map has genuinely stopped moving.
        func scheduleDeclutterRefresh(_ mapView: MKMapView) {
            pendingDeclutterRefresh?.cancel()
            let workItem = DispatchWorkItem { [weak self, weak mapView] in
                guard let self, let mapView else { return }
                self.annotationViewFactory.refreshDeclutterState(on: mapView)
                self.refreshPinSelection(mapView)
            }
            pendingDeclutterRefresh = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + DropinApp.map.declutterRefreshDebounce, execute: workItem)
        }

        // MARK: - pin/dot selection

        /// No-cluster-mode only. When clustering is on, MapKit handles density  natively and every place is a plain full pin
        /// so there's nothing to promote/demote here.
        func resetPromotedTracking() {
            promotedIds = []
        }

        /// Picks which places get a promoted (full pin) overlay on top of their permanent dot, capped at `DropinApp.map.maxDisplayPin`.
        /// Once promoted, a place stays promoted even after scrolling off-screen
        /// Demotion only happens if the combined candidate set (still-promoted + newly-visible)
        /// exceeds the cap, in which case the least-recently-updated ones are bumped.
        /// Selection policy: most-recently-updated first, id string as a stable tiebreak.
        // TODO: DRO-31
        // TODO: Improve the way the places are selected for promotion:
        //  grid-bucket the visible places by absolute map-point coordinates (not relative to the current viewport), pick the best candidate per occupied cell, then rank cells (not places) to fill the cap.
        //   - Spread: one winner per cell means Paris can't eat every slot, each geographic cell gets a fair shot regardless of local density.
        //   - Predictability: cell boundaries come from floor(mapPoint / cellSize) with a fixed cellSize, a place always lands in the same cell no matter where the viewport happens to sit, so a slightly-shifted rect naturally produces nearly the same promoted set instead of reshuffling.
        // TODO: or just rely on MAPKit collision test and create a pin for everyone
        func refreshPinSelection(_ mapView: MKMapView) {
            guard !mapSettings.clustering else {
                resetPromotedTracking()
                return
            }

            // Get the list of visible places in this rect
            let visible = mapView.annotations(in: mapView.visibleMapRect)
                .compactMap { $0 as? MKPlaceDotAnnotation }
            var candidates: [UUID: PlaceUI] = [:]
            for dot in visible { candidates[dot.id] = dot.place }

            // Sort the list so that higher position = higher chance to get promoted
            let sorted = candidates.sorted {
                if $0.value.updatedAt != $1.value.updatedAt {
                    return $0.value.updatedAt > $1.value.updatedAt
                }
                return $0.key.uuidString < $1.key.uuidString
            }

            // Created the set of promoted places (limited by `maxDisplayPin`)
            let newPromotedIds = Set(sorted.prefix(DropinApp.map.maxDisplayPin).map { $0.key })

            // Remove IDs that are already promoted
            let realPromotedIds = newPromotedIds.filter({ !promotedIds.contains($0) })

            // Create a list of annotations to be added
            let realPromotedCandidates = candidates
                .filter { realPromotedIds.contains($0.key) }
            let toAdd = realPromotedCandidates
                .map { MKPlacePromotedAnnotation(place: $0.value) }

            // Check the future list of visible annotations
            var toDemoteIds: [UUID] = []
            let nextVisiblePromotedIds = promotedIds
                .filter({ candidates[$0] != nil })
            let prospectiveCount = nextVisiblePromotedIds.count + realPromotedIds.count
            if prospectiveCount > DropinApp.map.maxDisplayPin {
                // We'll be exceeding the promoted annotations limit, we need to demote some
                let qtyToRemove = prospectiveCount - DropinApp.map.maxDisplayPin

                toDemoteIds = Array(nextVisiblePromotedIds
                    .filter({ !realPromotedIds.contains($0) })
                    .prefix(qtyToRemove))
            }
            // Add
            if !toAdd.isEmpty {
                mapView.addAnnotations(toAdd)
            }

            // Remove
            if !toDemoteIds.isEmpty {
                mapView.removeAnnotations(mapView.annotations
                    .compactMap({ $0 as? MKPlacePromotedAnnotation })
                    .filter({ toDemoteIds.contains($0.id) })
                )
            }
            
            // Update the cache
            promotedIds.subtract(toDemoteIds)
            promotedIds.formUnion(realPromotedIds)
        }

        // MARK: - private methods
        private func centerOn(_ mapView: MKMapView,
                              coords: CLLocationCoordinate2D,
                              withSheetOffset: Bool,
                              animated: Bool = true) {
            
            let sheetHeight: CGFloat? = withSheetOffset ? 400 : nil // FIXME: this value should be provided somehow
            let comfortableSpan: CLLocationDistance = 1_500 // 1500 meters
            
            let bottomPadding = sheetHeight ?? 0
            
            // -- Case 1: zoom in needed (current view is wider than comfortable) --
            let metersPerMP   = MKMetersPerMapPointAtLatitude(coords.latitude)
            let comfortable   = comfortableSpan / metersPerMP
            let current       = mapView.visibleMapRect.size.width
            
            if current > comfortable {
                let p = MKMapPoint(coords)
                let rect = MKMapRect(x: p.x - comfortable/2,
                                     y: p.y - comfortable/2,
                                     width: comfortable,
                                     height: comfortable)
                mapView.setVisibleMapRect(
                    rect,
                    edgePadding: UIEdgeInsets(top: 0, left: 0,
                                              bottom: bottomPadding, right: 0),
                    animated: animated)
                return
            }
            // else: already close enough — fall through to pan-only
            
            // -- Case 2: pan only (preserve zoom), apply sheet offset --
            guard bottomPadding > 0 else {
                mapView.setCenter(coords, animated: animated)
                return
            }
            let upwardShift = bottomPadding / 2
            let pinNow      = mapView.convert(coords, toPointTo: mapView)
            let newCenterPt = CGPoint(x: pinNow.x, y: pinNow.y + upwardShift)
            let newCenter   = mapView.convert(newCenterPt, toCoordinateFrom: mapView)
            mapView.setCenter(newCenter, animated: animated)
        }
    }
}


// MARK: - MKMapViewDelegate
extension PlacesMKMapVCR.Coordinator: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        annotationViewFactory.view(for: annotation, in: mapView)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard interactionStatus().selectionEnabled else {
            // Cancel the apple cluster default animation asap (another way would be to replace by our own cluster view)
            mapView.deselectAnnotation(view.annotation, animated: false)
            return
        }
        if let cluster = view.annotation as? MKClusterAnnotation {
            // Zoom into cluster
            mapView.showAnnotations(cluster.memberAnnotations, animated: true)
        } else if let placeAnnotation = view.annotation as? MKPlaceAnnotationRepresentable {
            view.isSelected = true
            centerOn(mapView,
                     coords: placeAnnotation.coordinate,
                     withSheetOffset: true,
                     animated: true)
            onPlaceSelected(placeAnnotation.id)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard view.annotation is MKPlaceAnnotationRepresentable else { return }
        view.isSelected = false
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard !hasSnappedToUser else {
            return
        }
        guard config.positionAtLaunch == .user else {
            return
        }
        guard let coordinate = userLocation.location?.coordinate else {
            return
        }
        hasSnappedToUser = true
        centerOn(coords: coordinate, withSheetOffset: false)
        //mapView.setCenter(coordinate, animated: true)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        if let onMapCameraUpdate = onMapCameraUpdate {
            onMapCameraUpdate(mapView.camera,
                              mapView.region,
                              mapView.visibleMapRect)
        }
        scheduleDeclutterRefresh(mapView)
        
        // TODO: REMOVE
        // checkLiveDecorrelation(mapView)
    }

    /// Fires on every continuous camera-change callback (i.e. mid-gesture, not
    /// debounced) — logs only when a visible annotation view's actual center
    /// diverges from where its coordinate + centerOffset says it should be
    /// *right now*, to catch a transient glitch during a live drag/pinch that a
    /// delayed, post-settle sample would never see.
    private func checkLiveDecorrelation(_ mapView: MKMapView) {
        for raw in mapView.annotations(in: mapView.visibleMapRect) {
            guard let annotation = raw as? MKAnnotation,
                  let view = mapView.view(for: annotation),
                  !view.isHidden else { continue }
            let projected = mapView.convert(annotation.coordinate, toPointTo: mapView)
            let expectedCenter = CGPoint(x: projected.x + view.centerOffset.x,
                                         y: projected.y + view.centerOffset.y)
            let dx = view.center.x - expectedCenter.x
            let dy = view.center.y - expectedCenter.y
            let distance = (dx * dx + dy * dy).squareRoot()

            // `view.center`/`.layer.position` is the CALayer *model* value — it updates
            // synchronously the instant MapKit sets it, regardless of what's actually
            // composited on screen. `layer.presentation()` is the value Core Animation
            // is currently rendering mid-animation. If MapKit smooths annotation-view
            // movement with an implicit/explicit position animation during a gesture,
            // the two diverge — and every prior check here, reading only the model
            // value, would be structurally blind to that gap.
            let presentationPosition = view.layer.presentation()?.position
            let presentationDistance = presentationPosition.map { p -> CGFloat in
                let pdx = p.x - view.layer.position.x
                let pdy = p.y - view.layer.position.y
                return (pdx * pdx + pdy * pdy).squareRoot()
            }

            guard distance > 2 || (presentationDistance ?? 0) > 2 else { continue }

            let name: String
            if let dot = annotation as? MKPlaceDotAnnotation {
                name = "DOT:'\(dot.place.name)'"
            } else if let pin = annotation as? MKPlacePromotedAnnotation {
                name = "PIN:'\(pin.place.name)'"
            } else {
                continue
            }
            Log.debug("[live] MISMATCH \(name) actual=\(view.center) expected=\(expectedCenter) diff=\(distance) presentation=\(String(describing: presentationPosition)) modelVsPresentationDiff=\(String(describing: presentationDistance))")
        }
    }
}


// MARK: - MapViewController
class PlacesMKMapVC: UIViewController {

    var mapView: MKMapView
    fileprivate weak var coordinator: PlacesMKMapVCR.Coordinator?
    fileprivate weak var appSettings: AppSettings?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.mapView = MKMapView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience init(coordinator: PlacesMKMapVCR.Coordinator) {
        self.init(nibName: nil, bundle: nil)
        self.coordinator = coordinator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let coordinator = coordinator else { fatalError("undefined coordinator") }
        
        mapView.delegate = coordinator
        
        mapView.showsUserLocation = coordinator.config.showsUserLocation
        mapView.mapType = .standard
        mapView.isScrollEnabled = coordinator.config.scrollEnabled
        mapView.isZoomEnabled = coordinator.config.zoomEnabled
        mapView.isRotateEnabled = coordinator.config.rotateEnabled
        mapView.isPitchEnabled = false
        mapView.userTrackingMode = .none
        switch coordinator.config.positionAtLaunch {
            case .user:
                ()
            case .region(let region):
                mapView.setRegion(region, animated: false)
            case .none:
                ()
        }

        coordinator.annotationViewFactory.registerViews(for: mapView)

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}


#if DEBUG

struct MockPlacesMKMapVCR: View {
    @State var places: [PlaceUI]
    @State var settings: AppSettings
    @State var clustering: Bool = true
    @State var selectedPlaceId: UUID?

    var body: some View {
        
        TabView {
            VStack {
                Button {
                    if selectedPlaceId == nil {
                        selectedPlaceId = places.randomElement()!.id
                    } else {
                        selectedPlaceId = nil
                    }
                } label: {
                    if selectedPlaceId == nil {
                        Text("Select random")
                    } else {
                        Text("UnSelect")
                    }
                }
                
                // INTERACTIVE TAB
                PlacesMKMapVCR(config: .interactive,
                               mapController: MapController(),
                               places: places,
                               selectedPlaceId: $selectedPlaceId,
                               //onPlaceSelected: { uuid in print("SELECTED PLACE \(uuid)") },
                               onLongPress: { coords in print("LONG PRESSED \(coords)") },
                               onMapCameraUpdate: onMapCameraUpdate,
                               interactionStatus: { return .all },
                               mapReloadGen: 0,
                               bottomInset: 0)
            }
            .tabItem {
                Label("Interactive", systemImage: "map")
            }

            // PREVIEW(SETTINGS) TAB
            VStack {
                PlacesMKMapVCR(config: PlacesMKMapVCR.Configuration(scrollEnabled: false,
                                                                    zoomEnabled: false,
                                                                    showsUserLocation: false,
                                                                    positionAtLaunch: .region(region: .barcelona
                                                                        .zoom(0.2))),
                               mapController: MapController(),
                               places: places,
                               draftCoordinate: .barcelona.offset(x: 0.02, y: -0.02),
                               selectedPlaceId: Binding<UUID?>.constant(nil),
                               interactionStatus: { return .none },
                               mapReloadGen: 0,
                               bottomInset: 0)
                Toggle(isOn: $settings.mapSettings.clustering) {
                    Text("Clustering")
                }
            }
            .padding(.horizontal)
            .tabItem {
                Label("Interactive", systemImage: "gear")
            }

        }
        .environment(settings)
    }
    
    private func onMapCameraUpdate(camera: MKMapCamera,
                                   region: MKCoordinateRegion,
                                   rect: MKMapRect) {
        //print("UP CAM")
    }
    
    init() {
        //let mock = MockContainer()
        //self.mock = mock
        let place1 = PlaceUI(coordinates: .barcelona)
        place1.group = GroupUI(color: "AE271A")
        let place2 = PlaceUI(coordinates: .barcelona.offset(x: 0.01))
        let place3 = PlaceUI(coordinates: .barcelona.offset(y: 0.01))
        let place4 = PlaceUI(coordinates: .barcelona.offset(x: 0.02, y: -0.02))
        let place5 = PlaceUI(coordinates: .barcelona.offset(x: 0.0201, y: -0.0201))
        self.places = [place1, place2, place3, place4, place5]
        
        settings = AppSettings()
        settings.mapSettings.satellite = false
        settings.mapSettings.pinStyle = .rounded
    }
}

#Preview {
    NavigationStack {
        MockPlacesMKMapVCR()
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
