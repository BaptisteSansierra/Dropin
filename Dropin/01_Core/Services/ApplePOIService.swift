//
//  ApplePOIService.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/26.
//

import Foundation
import MapKit

@MainActor
protocol ApplePOIServiceProtocol: AnyObject {
    func details(for id: String) async throws -> MKMapItem
    func details(for annotation: MKMapFeatureAnnotation) async throws -> MKMapItem
}

@MainActor
final class ApplePOIService: ApplePOIServiceProtocol {
    
    private let cache = ApplePOICache()
    private let reachability: any ReachabilityServiceProtocol

    init(reachability: any ReachabilityServiceProtocol) {
        self.reachability = reachability
    }
    
    func details(for id: String) async throws -> MKMapItem {
        do {
            switch cache.lookup(id) {
                case .fresh(let item):
                    return item
                case .stale(let item):
                    guard reachability.isConnected else { return item }
                    do {
                        return try await fetchAndCache(id)
                    }
                    catch {
                        return item
                    }
                case .miss:
                    return try await fetchAndCache(id)
            }
        } catch {
            throw mapError(error)
        }
    }
    
    func details(for annotation: MKMapFeatureAnnotation) async throws -> MKMapItem {
        // If details is requested from an annotation, it probably means there's no cache for it
        // Anyway we have no access to the ID, so we fetch
        do {
            return try await fetchAndCache(annotation)
        } catch {
            throw mapError(error)
        }
    }
    
    private func mapError(_ error: Error) -> Error {
        if let applePOIError = error as? ApplePOIError {
            return applePOIError
        }
        if let mkError = error as? MKError {
            switch mkError.code {
                case .placemarkNotFound:
                    return ApplePOIError.notFound
                case .serverFailure:
                    return ApplePOIError.notConnected
                default:
                    Log.error("MKError: \(mkError.code.rawValue) \(mkError.localizedDescription)")
                    return ApplePOIError.mkUnknown(mkError.code.rawValue)
            }
        }
        return ApplePOIError.unknown(error)
    }
    
    private func fetchAndCache(_ id: String) async throws -> MKMapItem {
        guard let identifier = MKMapItem.Identifier(rawValue: id) else { throw ApplePOIError.corrupted }
        let item = try await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
        cache.set(item, for: id)
        if let fetchedId = item.identifier?.rawValue, fetchedId != id {
            cache.set(item, for: fetchedId)
        }
        return item
    }
    
    private func fetchAndCache(_ annotation: MKMapFeatureAnnotation) async throws -> MKMapItem {
        let item = try await MKMapItemRequest(mapFeatureAnnotation: annotation).mapItem
        if let id = item.identifier {
            // the returned item can have no identifier. It has been reported missing on some devices with iOS 18.
            cache.set(item, for: id.rawValue)
        }
        return item
    }
}

// TODO: cleanup: make it different files

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

enum ApplePOIError: Error, Equatable {
    /// it seems the Apple POI was deleted Apple side
    case notFound
    /// server error when requesting apple POI
    case notConnected
    /// stored identifier is not recognized by apple... invalid ID ? that shouldn't happen
    case corrupted
    // Unexpected MK domain error
    case mkUnknown(UInt)
    // Unexpected error
    case unknown(Error)
    
    static func == (lhs: ApplePOIError, rhs: ApplePOIError) -> Bool {
        switch(lhs, rhs) {
            case (.notFound, .notFound):
                return true
            case (.notConnected, .notConnected):
                return true
            case (.corrupted, .corrupted):
                return true
            case (.mkUnknown, .mkUnknown):
                return true
            case (.unknown, .unknown):
                return true
            default:
                return false
        }
    }

}
