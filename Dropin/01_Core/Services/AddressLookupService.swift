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

final class AddressLookupService: NSObject {
    
    // Mark as nonisolated(unsafe) since we control the access pattern
    // This remove warnings until Apple's MapKit types has been audited for Sendable, could probably be removed then
    //private nonisolated(unsafe) var queryContinuation: CheckedContinuation<[MKLocalSearchCompletion], any Error>?
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
        queryContinuation?.resume(throwing: CancellationError())
        queryContinuation = nil

        return try await withCheckedThrowingContinuation { continuation in
            queryContinuation = continuation
            completer.queryFragment = query
        }
    }
}

extension AddressLookupService: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        //Task { @MainActor in
            queryContinuation?.resume(returning: completer.results.map({ LookupResult(localSearchCompletion: $0) }))
            queryContinuation = nil
        //}

//        let p: MKMapItem
//        p.pointOfInterestCategory
//        
        for r in completer.results {
            print("R: \(r.title)")
            print("   \(r.subtitle)")
            print("   \(r.description)")
            print("---------")
        }
        /*

        Task {
            if let first = completer.results.first {
                let request = MKLocalSearch.Request(completion: first)
                let search = MKLocalSearch(request: request)
                do {
                    let response = try await search.start()
                    print("FIRST LOC FOUND : ")
                    print("Name: \(response.mapItems.first!.name)")
                    if #available(iOS 26.0, *) {
                        print("Address: \(response.mapItems.first!.address)")
                    } else {
                        if let postalAddress = response.mapItems.first!.placemark.postalAddress {
                            let formatter = CNPostalAddressFormatter()
                            let addressString = formatter.string(from: postalAddress)
                            print("Address Postal: \(addressString)")
                        }
                    }
                    print("Phone: \(response.mapItems.first!.phoneNumber)")
                    print("URL: \(response.mapItems.first!.url)")

                } catch {
                    print("oulala")
                }
            }
        }
         */
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        queryContinuation?.resume(throwing: error)
        queryContinuation = nil
    }
}
