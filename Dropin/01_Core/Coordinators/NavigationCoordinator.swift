//
//  NavigationCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/6/26.
//

import Foundation

@MainActor
protocol NavigationCoordinator {
    associatedtype Item: Hashable
    var path: [Item] { get set }
    
    func pop()
}

@MainActor
protocol PlaceNavigationCoordinator: NavigationCoordinator {
    func pushPlaceEditView(placeRef: PlaceUIRef)
}
