//
//  LookupPlacesViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

import SwiftUI
import MapKit

@MainActor
@Observable class LookupPlacesViewModel {
    
    // MARK: Properties
    var results: [LookupResult] = []
    var lookupError: Error?
    var query: String = "" {
        didSet {
            
            guard query.count > 2 else {
                results = []
                lookupError = nil
                return
            }
            Task {
                do {
                    results = try await addressLookupService.search(query: query)
                    lookupError = nil
                } catch let error as CancellationError {
                    // silent it
                } catch {
                    results = []
                    lookupError = error
                }
            }
        }
    }

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var addressLookupService: AddressLookupService

    // MARK: - init
    init(_ appContainer: AppContainer,
         addressLookupService: AddressLookupService) {
        self.appContainer = appContainer
        self.addressLookupService = addressLookupService
    }

    // MARK: - UI child
    func createLookupPlaceView(_ lookupResult: LookupResult) -> LookupPlaceView {
        return appContainer.createLookupPlaceView(lookupResult: lookupResult)
    }
}
