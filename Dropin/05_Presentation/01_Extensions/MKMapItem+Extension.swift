//
//  MKMapItem+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import MapKit
import Contacts

extension MKMapItem {
    
    func icon() -> Icon {
        let defaultIcon = Icon.sf("plus.circle")
        guard let category = pointOfInterestCategory else {
            return defaultIcon
        }
        return category.icon
    }
    
    func resolvedAddress() -> String? {
        if #available(iOS 26.0, *) {
            // `MKAddress.fullAddress` has no single/multi-line guarantee; `MKAddressRepresentations`
            // does (singleLine: false), matching CNPostalAddressFormatter's multiline output below.
            if let representations = addressRepresentations {
                return representations.fullAddress(includingRegion: true, singleLine: false)
            }
        } else {
            if let postalAddress = placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                return formatter.string(from: postalAddress)
            }
        }
        return nil
    }
    
// TODO: remove
//    func toApplePOIDetails(_ srcId: String? = nil) -> ApplePOIDetails {
//        // This MapItem was first fetched from a source id (given as parameter)
//        // If MapItem's identifier is not nil (which should not happen ?), use this id instead of the source
//        var poiId = srcId
//        if let appleLatestId = identifier?.rawValue {
//            // Apple could give a different id from the source in case of POI update (duplicates, ...)
//            poiId = appleLatestId
//        }
//        return ApplePOIDetails(appleId: poiId, phoneNumber: phoneNumber, url: url)
//    }
    
    /// fallback when there's no street address. Never persist it as the address.
    func resolvedArea() -> String? {
        if #available(iOS 26.0, *) {
            return addressRepresentations?.cityWithContext?.nonEmpty
        } else {
            let parts = [placemark.subLocality, placemark.locality ?? placemark.administrativeArea]
                .compactMap { $0?.nonEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }
    
    func resolvedCoordinates() -> CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            return location.coordinate
        } else {
            return placemark.coordinate
        }
    }
}
