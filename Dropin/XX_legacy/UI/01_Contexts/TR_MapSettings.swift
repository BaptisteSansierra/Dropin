//
//  MapSettings.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import MapKit

/// MapSettings owns the main map display settings values
@Observable class MapSettings {

    // MARK: - Computed properties
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

    // MARK: - Published properties
    /// `position` can be used to set the main map camera position
    var position: MapCameraPosition = .automatic
    /// `currentCameraCenter` can be used to get the main map current camera center
    var currentCameraCenter = CLLocationCoordinate2D()
    /// `currentCameraDistance` can be used to get the main map current camera distance
    var currentCameraDistance: Double = 0
    /// `currentRegionSpan` can be used to get the main map current region span distance
    var currentRegionSpan = MKCoordinateSpan()
    /// `hidePointsOfInterest` show/hide the POI in the main map
    var hidePointsOfInterest = true
    /// `satellite` enable/disable the satellite view in the main map
    var satellite = false
    /// `settingsShown` show/hide the settings menu in the main map
    var settingsShown = false
}
