//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import Foundation
import CoreLocation

@Observable class Place {
        
    // MARK: public vars
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var systemImage: String = "tag"
    var tags: [SDTag] = []
    var group: SDGroup? = nil
    var notes: String? = nil
    var phone: String? = nil
    var url: String? = nil
    
    // MARK: private vars
    /// Seed is empty when Place is created for creation, and defined for edition
    private var seed: SDPlace? = nil
    
    // MARK: init
    init() {
    }

    init(sdPlace: SDPlace) {
        seed = sdPlace
        reloadFromSeed()
    }
    
    // MARK: public
    func toSDPlace() -> SDPlace {
        guard seed == nil else {
            fatalError("toSDPlace cannot be called when seed defined, should only be used to create new entry")
        }
        return SDPlace(name: name,
                       latitude: coordinates.latitude,
                       longitude: coordinates.longitude,
                       address: address,
                       systemImage: systemImage,
                       tags: tags,
                       group: group,
                       notes: notes,
                       phone: phone,
                       url: url)
    }
    
    func getSeed() -> SDPlace {
        guard let seed = seed else {
            fatalError("No seed defined here")
        }
        return seed
    }
    
    /// Reload data from seed (origin SDPlace)
    func reloadFromSeed() {
        guard let seed = seed else {
            assertionFailure("reloadFromSeed called with no seed")
            return
        }
        name = seed.name
        coordinates = CLLocationCoordinate2D(latitude: seed.latitude, longitude: seed.longitude)
        address = seed.address
        systemImage = seed.systemImage
        tags = seed.tags
        group = seed.group
        notes = seed.notes
        phone = seed.phone
        url = seed.url
    }
    
    /// Apply changes to the seed (origin SDPlace)
    func applyChanges() {
        guard let seed = seed else {
            assertionFailure("applyChanges called with no seed")
            return
        }
        seed.name = name
        seed.latitude = coordinates.latitude
        seed.longitude = coordinates.longitude
        seed.address = address
        seed.systemImage = systemImage
        seed.tags = tags
        seed.group = group
        seed.notes = notes
        seed.phone = phone
        seed.url = url
    }
}
