//
//  AddressBackfillService.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/9/26.
//

import Foundation
import CoreLocation

protocol AddressBackfillServiceProtocol: Sendable {
    /// Fires a background reverse-geocode lookup for `place` if (and only if) it has no address yet. Safe to call repeatedly and from multiple call sites
    /// no-ops if the place already has an address or a lookup is already in flight for it.
    /// Fire-and-forget: on failure (including offline) it just leaves the address nil, to be retried on the next call.
    @MainActor func backfillIfNeeded(_ place: PlaceEntity)
}

///  A place's address can be nil, not yet fetched, e.g. created offline.
///  This service is the single place that tries to fill it in afterwards, so callers (the sync pull loop, the place repository's read path)
/// just report "this place has no address" without each duplicating the fetch/dedupe/persist logic themselves.
@MainActor
final class AddressBackfillService: AddressBackfillServiceProtocol {

    /// Try to never reach Apple's reverse-geocode rate limit
    private static let delayBetweenRequests: Duration = .seconds(1.5)

    /// Writes resolved addresses back through here. Should be the syncing-decorated
    /// repository, so a backfilled address is marked dirty and gets pushed remotely like any other local edit.
    private let repository: any PlaceRepository
    private let reachability: any ReachabilityServiceProtocol

    /// Places queued for backfill, in FIFO order.
    private var queue: [PlaceEntity] = []
    private var inFlight: Set<UUID> = []
    private var isDraining = false

    init(repository: any PlaceRepository, reachability: any ReachabilityServiceProtocol) {
        self.repository = repository
        self.reachability = reachability
    }

    func backfillIfNeeded(_ place: PlaceEntity) {
        guard place.address == nil else { return }
        guard reachability.isConnected else { return }
        guard !inFlight.contains(place.id) else { return }
        inFlight.insert(place.id)
        queue.append(place)
        startDrainingIfNeeded()
    }

    // MARK: - private

    private func startDrainingIfNeeded() {
        guard !isDraining else { return }
        isDraining = true
        Task { [weak self] in
            await self?.drain()
        }
    }

    private func drain() async {
        while !queue.isEmpty {
            let place = queue.removeFirst()
            await process(place)
            if !queue.isEmpty {
                try? await Task.sleep(for: Self.delayBetweenRequests)
            }
        }
        isDraining = false
    }

    private func process(_ place: PlaceEntity) async {
        defer { inFlight.remove(place.id) }
        guard reachability.isConnected else { return }
        do {
            let address = try await LocationManager.lookUpAddress(coords: place.coordinates)
            // Re-fetch: the place may have been edited (incl. address set by
            // hand) or deleted while the lookup was in flight.
            let current = try await repository.fetch(place.id)
            guard current.address == nil else { return }
            try await repository.update(current.withAddress(address))
        } catch {
            Log.debug("AddressBackfillService: couldn't backfill address for place \(place.id): \(error)")
        }
    }
}
