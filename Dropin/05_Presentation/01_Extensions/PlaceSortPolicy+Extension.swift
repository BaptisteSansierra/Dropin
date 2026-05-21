//
//  PlaceSortPolicy+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/4/26.
//

import Foundation
import CoreLocation

extension PlaceSortPolicy {
    
    @MainActor
    func apply(_ places: [PlaceUI], userPosition: CLLocationCoordinate2D?) -> [PlaceUI] {
        switch self {
            case .alphabetically:
                return places.sorted { p1, p2 in
                    if p1.name.compare(p2.name) == .orderedSame {
                        return p1.createdAt.compare(p2.createdAt) == .orderedAscending
                    }
                    return p1.name.compare(p2.name) == .orderedAscending
                }
            case .createdAt:
                return places.sorted { p1, p2 in
                    return p1.createdAt.compare(p2.createdAt) == .orderedAscending
                }
            case .distance:
                return places.sorted { p1, p2 in
                    guard let userPosition = userPosition else {
                        if p1.name.compare(p2.name) == .orderedSame {
                            return p1.createdAt.compare(p2.createdAt) == .orderedAscending
                        }
                        return p1.name.compare(p2.name) == .orderedAscending
                    }
                    let d1 = userPosition.distance(to: p1.coordinates)
                    let d2 = userPosition.distance(to: p2.coordinates)
                    return d1 < d2
                }
        }

    }
}
