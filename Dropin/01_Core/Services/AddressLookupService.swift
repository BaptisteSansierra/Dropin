//
//  AddressLookupService.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

@preconcurrency import MapKit

struct LookupResult: Identifiable, Sendable {
    let localSearchCompletion: MKLocalSearchCompletion
    let id: String
    
    init(localSearchCompletion: MKLocalSearchCompletion) {
        self.localSearchCompletion = localSearchCompletion
        self.id = UUID().uuidString
    }
}

@MainActor
final class AddressLookupService: NSObject {
    
    private var queryContinuation: CheckedContinuation<[LookupResult], any Error>?
    private let completer: MKLocalSearchCompleter
    private let locationManager: LocationManager

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
    }
    
    func search(query: String) async throws -> [LookupResult] {
        // Update region
        if let location = locationManager.lastKnownLocation {
            completer.region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        // Cancel any in-flight continuation
        if let old = queryContinuation {
            queryContinuation = nil
            old.resume(throwing: CancellationError())
        }

        return try await withCheckedThrowingContinuation { continuation in
            queryContinuation = continuation
            completer.queryFragment = query
        }
    }
    
    // Private methods to handle results on MainActor
    private func handleResults(_ results: [MKLocalSearchCompletion]) {
        guard let continuation = queryContinuation else { return }
        queryContinuation = nil
        
        let lookupResults = results.map { LookupResult(localSearchCompletion: $0) }
        continuation.resume(returning: lookupResults)
        
        //        let p: MKMapItem
        //        p.pointOfInterestCategory
        //
        for r in results {
            print("R: \(r.title)")
            print("   \(r.subtitle)")
            print("   \(r.description)")
            print("---------")
        }
    }
    
    private func handleError(_ error: Error) {
        guard let continuation = queryContinuation else { return }
        queryContinuation = nil
        
        continuation.resume(throwing: error)
    }
}

@MainActor
extension AddressLookupService: MKLocalSearchCompleterDelegate {
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            handleResults(completer.results)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        Task { @MainActor in
            handleError(error)
        }
    }
}
