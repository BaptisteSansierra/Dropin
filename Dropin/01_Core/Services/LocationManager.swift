//
//  LocationManager.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import CoreLocation
import Contacts

enum LocationManagerError: Error {
    case lookupFailure
}

/// `LocationManager` owns the current location and CoreLocation authorization status
/// It also handles location utilities such as address from coordinates and so onj
@Observable class LocationManager: NSObject {
    
    // MARK: - observed vars
    private(set) var lastKnownLocation: CLLocationCoordinate2D?
    private(set) var authorized: Bool?

    // MARK: - not observed vars
    @ObservationIgnored private var manager = CLLocationManager()
    @ObservationIgnored private var started = false
    @ObservationIgnored private lazy var distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .short
        return formatter
    }()
    
    override init() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }
    
    func start() {
        started = true
        manager.delegate = self
        lastKnownLocation = manager.location?.coordinate
        checkAuthorizationStatus()
        guard let _ = authorized else { return }
        //manager.requestLocation()
        manager.startMonitoringSignificantLocationChanges()
    }
    
    private func checkAuthorizationStatus() {
        switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                authorized = true
            case .denied, .restricted:
                authorized = false
            @unknown default:
                authorized = false
        }
    }
}

// MARK: - Conform CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLoc = locations.first else { return }
        lastKnownLocation = firstLoc.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard started else { return }
        start()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Log.error("error getting location: \(error.localizedDescription)")
    }
}

// MARK: - distance utils
extension LocationManager {
    
    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let l1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let l2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return l1.distance(from: l2)
    }
    
    func distanceTo(_ coords: CLLocationCoordinate2D) -> Double? {
        guard let loc = lastKnownLocation else { return nil }
        return LocationManager.distance(from: loc, to: coords)
    }
    
    func distanceStringTo(_ coords: CLLocationCoordinate2D) -> String? {
        guard let distance = distanceTo(coords) else { return nil }
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        // Adjust precision
        distanceFormatter.numberFormatter.maximumFractionDigits = distance < 10000 ? 1 : 0
        return distanceFormatter.string(from: measurement)
        
//        guard let d = distanceTo(coords) else { return nil }
//        if d < 900 {
//            return "\(Int(d))m"
//        } else if d < 10000 {
//            return "\(String(format: "%.1f", d / 1000))km"
//        }
//        return "\(String(format: "%.0f", d / 1000))km"
    }
}

// MARK: - address utils
extension LocationManager {

    static func lookUpAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            lookUpAddressWithCompletion(coords: coords) { result in
                if let value = result {
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(throwing: LocationManagerError.lookupFailure)
                }
            }
        }
    }

    static private func lookUpAddressWithCompletion(coords: CLLocationCoordinate2D, completion: @Sendable @escaping (String?)->() ) {
        let location = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
        let geocoder = CLGeocoder()
        geocoder.cancelGeocode() // Cancel pending requests
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let error = error {
                Log.error("couldn't get address from coords \(coords): \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let placemark = placemarks?[0] else {
                Log.error("no address found from coords \(coords)")
                completion(nil)
                return
            }
            if let postalAddress = placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                let postalAddressStr = formatter.string(from: postalAddress)
                if !postalAddressStr.isEmpty {
                    completion(postalAddressStr)
                    return
                }
            }
            var readable = ""
            if let streetName = placemark.thoroughfare {
                if let streetNumber = placemark.subThoroughfare {
                    readable = "\(streetNumber) \(streetName), "
                } else {
                    readable = "\(streetName), "
                }
            }
            if let zipCode = placemark.postalCode {
                readable = "\(readable)\(zipCode) "
            }
            if let city = placemark.locality {
                readable = "\(readable)\(city) "
            }
            if let state = placemark.administrativeArea {
                readable = "\(readable)\(state) "
            }
            if let country = placemark.country {
                readable = "\(readable)\(country) "
            }
            if let inlandWater = placemark.inlandWater {
                readable = "\(readable)\(inlandWater) "
            }
            if let ocean = placemark.ocean {
                readable = "\(readable)\(ocean) "
            }
            completion(readable)
        })
    }
}
