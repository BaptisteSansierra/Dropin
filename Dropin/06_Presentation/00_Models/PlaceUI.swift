//
//  PlaceUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI
import CoreLocation
import ContactFieldKit

@MainActor
@Observable class PlaceUI: Identifiable, @MainActor Equatable {

    let id: UUID
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var address2: String = ""
    var icon: Icon? = nil
    var tags: [TagUI] = [TagUI]()
    var group: GroupUI? = nil
    var rating: Float? = nil
    var phone: [ContactItem] = []
    var email: [ContactItem] = []
    var url: [ContactItem] = []
    var notes: String? = nil
    var images: [Data] = []
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, UI objects should be ignored
    var databaseDeleted: Bool = false

    var groupColor: Color {
        guard let group = self.group else { return .dropinPrimary }
        return group.color
    }

    var changeToken: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(coordinates)
        hasher.combine(address)
        hasher.combine(address2)
        hasher.combine(icon?.rawValue)
        hasher.combine(tags.map(\.id))
        hasher.combine(group?.id)
        hasher.combine(rating)
        hasher.combine(phone.map(\.rawValue))
        hasher.combine(email.map(\.rawValue))
        hasher.combine(url.map(\.rawValue))
        hasher.combine(notes)
        return hasher.finalize()
    }

    static func == (lhs: PlaceUI, rhs: PlaceUI) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         address2: String,
         tags: [TagUI],
         group: GroupUI? = nil,
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [ContactItem] = [],
         email: [ContactItem] = [],
         url: [ContactItem] = [],
         notes: String? = nil,
         images: [Data] = [],
         creationDate: Date,
         databaseDeleted: Bool) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.address2 = address2
        self.tags = tags
        self.group = group
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.images = images
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }

    init(coordinates: CLLocationCoordinate2D) {
        id = UUID()
        self.coordinates = coordinates
        creationDate = Date()
    }
    
    func copy() -> PlaceUI {
        return PlaceUI(id: id,
                       name: name,
                       coordinates: coordinates,
                       address: address,
                       address2: address2,
                       tags: tags,
                       group: group,
                       icon: icon,
                       rating: rating,
                       phone: phone,
                       email: email,
                       url: url,
                       notes: notes,
                       images: images,
                       creationDate: creationDate,
                       databaseDeleted: databaseDeleted)
    }
    
    func isContentEqual(_ other: PlaceUI) -> Bool {
        guard id == other.id else { return false }
        guard name == other.name else { return false }
        guard coordinates == other.coordinates else { return false }
        guard address == other.address else { return false }
        guard address2 == other.address2 else { return false }
        guard tags == other.tags else { return false }
        guard group == other.group else { return false }
        guard icon == other.icon else { return false }
        guard rating == other.rating else { return false }
        guard phone == other.phone else { return false }
        guard email == other.email else { return false }
        guard url == other.url else { return false }
        guard notes == other.notes else { return false }
        guard images == other.images else { return false }
        return true
    }
}
