//
//  ApplePOICache.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

import Foundation
import MapKit

/// Stores provided MKMapItem during the app session
/// App session can live a long time in background if user does not explicitly kill the app
///  -> Consider the data is stale after 3 days old
/// If online, stale data is fetched again and replaced; if offline it is re-used
@MainActor
final class ApplePOICache {
    private struct Entry {
        let item: MKMapItem;
        let date: Date
    }
    private var entries: [String: Entry] = [:]
    private let maxAge: TimeInterval = 3 * 24 * 60 * 60  // Refrash a POI after 3 days old

    enum Lookup {
        case fresh(MKMapItem)
        case stale(MKMapItem)
        case miss
    }

    func lookup(_ id: String) -> Lookup {
        guard let e = entries[id] else { return .miss }
        return Date().timeIntervalSince(e.date) < maxAge ? .fresh(e.item) : .stale(e.item)
    }
    
    func set(_ item: MKMapItem, for id: String) {
        entries[id] = Entry(item: item, date: Date())
    }
}
