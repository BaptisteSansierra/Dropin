//
//  ClusterAnnotationModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

#if false

import Foundation
import CoreLocation
import MapKit

struct ClusterAnnotationModel: Identifiable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var count: Int
    var span: MKCoordinateSpan
}

#endif
