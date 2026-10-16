//
//  ApplePOISheetViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/26.
//

import SwiftUI
import MapKit

@MainActor
@Observable class ApplePOISheetViewModel {

    var error: Error?
    // Resolved map item from MKMapFeatureAnnotation
    var mapItem: MKMapItem?
    // A mapItem copy, set when the detailed sheet should be presented
    var presentedMapItem: MKMapItem?
    
    @ObservationIgnored private let applePOIService: any ApplePOIServiceProtocol
    @ObservationIgnored let applePOIAnnotation: MKMapFeatureAnnotation

    init(applePOIAnnotation: MKMapFeatureAnnotation,
         applePOIService: any ApplePOIServiceProtocol) {
        self.applePOIAnnotation = applePOIAnnotation
        self.applePOIService = applePOIService
    }
        
    func load() async {
        do {
            mapItem = try await applePOIService.details(for: applePOIAnnotation)
        } catch {
            self.error = error
        }
    }
}

