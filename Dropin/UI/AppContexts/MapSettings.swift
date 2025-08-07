//
//  MapSettings.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import MapKit

@Observable class MapSettings {

    // Computed properties
    var selectedMapStyle: MapStyle {
        if satellite {
            return .hybrid(elevation: .flat,
                           pointsOfInterest: hidePointsOfInterest ? PointOfInterestCategories.including([MKPointOfInterestCategory.publicTransport]) : .all,
                           showsTraffic: false)
        }
        return .standard(elevation: .flat,
                         pointsOfInterest: hidePointsOfInterest ? PointOfInterestCategories.including([MKPointOfInterestCategory.publicTransport]) : .all,
                         showsTraffic: false)
    }
    var settingsOpacity: CGFloat { settingsShown ? 1 : 0 }
    var settingsOffsetY: CGFloat { settingsShown ? 0 : -20 }

    // Published
    var position: MapCameraPosition = .automatic
    var currentCenter = CLLocationCoordinate2D()
    var hidePointsOfInterest = true
    var satellite = false
    var settingsShown = false
}
