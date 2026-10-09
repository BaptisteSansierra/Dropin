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

    // MARK: private properties
    // Keep a cache of fetched items
    private let cache = ApplePOICache()
    private let reachability: any ReachabilityServiceProtocol

    // MARK: init
    init(reachability: any ReachabilityServiceProtocol) {
        self.reachability = reachability
    }
    
    // MARK: ApplePOIServiceProtocol impl
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
    
    // MARK: private methods
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
