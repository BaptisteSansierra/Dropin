//
//  MainCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/1/26.
//

import SwiftUI
import CoreLocation

@MainActor
@Observable class MainCoordinator {
    
    struct NavigationEvent {
        let from: NavigationItem?
        let to: NavigationItem?
        let timestamp: Date
        let action: Action
        
        enum Action {
            case push
            case pop
        }
    }
    
    // MARK: properties
    var path: [NavigationItem] = [] {
        didSet {
            //print("COORDINATOR path : \(path.map({ "\($0)" }).joined(separator: "/"))")
            trackNavigation(oldPath: oldValue, newPath: path)
        }
    }
    private(set) var navigationHistory: [NavigationEvent] = []
    var lastNavigationSource: NavigationItem? {
        navigationHistory.last?.from
    }
    
    // MARK: navigation methods
    
    func pushPlaceEditView(placeId: UUID) {
        push(NavigationItem.placeEditView(placeId: placeId))
    }
    
    func pushLookupPlacesView() {
        push(NavigationItem.lookupPlacesView)
    }

//    func pushDropAPinView() {
//        push(NavigationItem.dropAPin)
//    }

    func pushLookupPlacesEditView(placeId: UUID) {
        push(NavigationItem.lookupPlacesEditView(placeId: placeId))
    }

    func pushCreatePlaceFullView(coordinates: CLLocationCoordinate2D,
                                 address: String,
                                 name: String,
                                 marker: String?,
                                 tags: [UUID],
                                 group: UUID?) {
        push(NavigationItem.placeCreateView(coordinates: coordinates,
                                            address: address,
                                            name: name,
                                            marker: marker,
                                            tags: tags,
                                            group: group))
    }

    func pushUndefinedDummyView() {
        push(NavigationItem.undefinedDummyView)
    }
    
    private func push(_ item: NavigationItem) {
        path.append(item)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    // MARK: history methods
    func trackNavigation(oldPath: [NavigationItem], newPath: [NavigationItem]) {
        guard newPath.count > oldPath.count else {
            // Pop
            navigationHistory.append(NavigationEvent(
                from: oldPath.last,
                to: newPath.last,
                timestamp: Date(),
                action: .pop
            ))
            return
        }
        // Push
        navigationHistory.append(NavigationEvent(
            from: oldPath.last,
            to: newPath.last,
            timestamp: Date(),
            action: .push
        ))
    }
}

enum NavigationItem: Hashable {
    case placeEditView(placeId: UUID)
    case lookupPlacesView
    case lookupPlacesEditView(placeId: UUID)
    case placeCreateView(coordinates: CLLocationCoordinate2D,
                         address: String,
                         name: String,
                         marker: String?,
                         tags: [UUID],
                         group: UUID?)
    case dropAPin
    // development
    case undefinedDummyView
}

extension NavigationItem {
    enum Kind {
        case placeEditView
        case lookupPlacesView
        case lookupPlacesEditView
        case placeCreateView
        case dropAPin
        case undefinedDummyView
    }

    var kind: Kind {
        switch self {
            case .placeEditView:
                return .placeEditView
            case .lookupPlacesView:
                return .lookupPlacesView
            case .lookupPlacesEditView:
                return .lookupPlacesEditView
            case .placeCreateView:
                return .placeCreateView
            case .dropAPin:
                return .dropAPin
            case .undefinedDummyView:
                return .undefinedDummyView
        }
    }
}
