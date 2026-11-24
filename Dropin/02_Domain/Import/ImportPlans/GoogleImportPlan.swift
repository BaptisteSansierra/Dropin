//
//  GoogleImportPlan.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/11/26.
//

import Foundation
import CoreLocation

struct GooglePlace: Sendable {
    let id: UUID
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String
    let url: String
    let review: String?
    let rating: Int?
}

struct GoogleImportPlan: Sendable {
    let places: [GooglePlace]
}
