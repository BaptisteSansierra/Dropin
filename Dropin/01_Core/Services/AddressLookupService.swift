//
//  AddressLookupService.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

@preconcurrency import MapKit

struct LookupResult: Identifiable, Sendable {
    let localSearchCompletion: MKLocalSearchCompletion
    let isPOI: Bool
    let id: String
    
    init(localSearchCompletion: MKLocalSearchCompletion, isPOI: Bool = false) {
        self.localSearchCompletion = localSearchCompletion
        self.isPOI = isPOI
        self.id = UUID().uuidString
    }
}

@MainActor
final class AddressLookupService: NSObject {
    
    // When useRefineCompleter is true, use a 2nd request to differentiate simple addresses from POI
    private let useRefineCompleter = true
    private var queryContinuation: CheckedContinuation<[LookupResult], any Error>?
    private let completer: MKLocalSearchCompleter
    private let refineCompleter: MKLocalSearchCompleter
    private let locationManager: LocationManager
    private var allResults: [MKLocalSearchCompletion] = []
    private var poiResults: [MKLocalSearchCompletion] = []
    private var allCompleted = false
    private var poiCompleted = false
    private var allError: Error?
    private var poiError: Error?

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest, .physicalFeature]
        refineCompleter = MKLocalSearchCompleter()
        refineCompleter.resultTypes = .pointOfInterest
        super.init()
        if let coords = locationManager.lastKnownLocation {
            completer.region = MKCoordinateRegion(center: coords,
                                                  span: .init(squareDelta: 0.3))
            refineCompleter.region = completer.region
        }
        completer.delegate = self
        refineCompleter.delegate = self
    }
    
    func search(query: String) async throws -> [LookupResult] {
        // Update region
        if let location = locationManager.lastKnownLocation {
            completer.region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            refineCompleter.region = completer.region
        }
        
        // Cancel any in-flight continuation
        if let old = queryContinuation {
            queryContinuation = nil
            old.resume(throwing: CancellationError())
        }
        
        // Reset results
        allResults.removeAll()
        poiResults.removeAll()
        allCompleted = false
        poiCompleted = false
        allError = nil
        poiError = nil

        // Create a continuation
        return try await withCheckedThrowingContinuation { continuation in
            queryContinuation = continuation
            // Initiate the search
            completer.queryFragment = query
            if useRefineCompleter {
                refineCompleter.queryFragment = query
            }
        }
    }
    
    private func handleResults(_ completer: MKLocalSearchCompleter) {
        guard let continuation = queryContinuation else {
            // Continuation should be define here to propagate the result
            // When nil, it means a new request was sent already and this result can be ignored
            return
        }
        guard useRefineCompleter else {
            // Not using refined results, we're done
            queryContinuation = nil
            
            let lookupResults = completer.results.map { LookupResult(localSearchCompletion: $0) }
            continuation.resume(returning: lookupResults)
            return
        }
        // When using refined results, we need to wait for both requests to be terminated
        if completer == self.completer {
            allResults = completer.results
            allCompleted = true
        } else if completer == refineCompleter {
            poiResults = completer.results
            poiCompleted = true
        }
        completeIfNeeded()
    }
    
    private func handleError(_ completer: MKLocalSearchCompleter, error: Error) {
        guard let continuation = queryContinuation else { return }
        guard useRefineCompleter else {
            queryContinuation = nil
            continuation.resume(throwing: error)
            return
        }
        if completer == self.completer {
            allResults = []
            allCompleted = true
            allError = error
        } else if completer == refineCompleter {
            poiResults = []
            poiCompleted = true
            poiError = error
        }
        completeIfNeeded()
    }
    
    private func completeIfNeeded() {
        guard let continuation = queryContinuation else { return }
        guard useRefineCompleter else {
            fatalError("This should only be called for dual requests")
        }
        // Check both requests ended
        guard allCompleted && poiCompleted else { return }
        // Both requests ended with error, throw the error
        if let allError = allError, let _ = poiError {
            queryContinuation = nil
            continuation.resume(throwing: allError)
            return
        }
        // One request ended with error, use the result we got
        if let _ = poiError {
            queryContinuation = nil
            let lookupResults = completer.results.map { LookupResult(localSearchCompletion: $0) }
            continuation.resume(returning: lookupResults)
            return
        }
        if let _ = allError {
            queryContinuation = nil
            let lookupResults = refineCompleter.results.map { LookupResult(localSearchCompletion: $0, isPOI: true) }
            continuation.resume(returning: lookupResults)
            return
        }
        // Merge results from 2 requests
        let results: [LookupResult] = allResults.map { localSearchCompletion in
            if let _ = poiResults.firstIndex(where: {
                localSearchCompletion.title == $0.title && localSearchCompletion.subtitle == $0.subtitle
            }) {
                return LookupResult(localSearchCompletion: localSearchCompletion, isPOI: true)
            }
            return LookupResult(localSearchCompletion: localSearchCompletion)
        }
        queryContinuation = nil
        continuation.resume(returning: results)
    }
}

@MainActor
extension AddressLookupService: MKLocalSearchCompleterDelegate {
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            handleResults(completer)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        Task { @MainActor in
            handleError(completer, error: error)
        }
    }
}
