//
//  _Utils.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/26.
//

import Foundation
import Testing
import CoreLocation
import ContactFieldKit
@testable import Dropin


// MARK: - Field-by-field comparison helpers
public  func assertEqualPlace(_ a: Place,
                              _ b: Place,
                              skipRelationships: Bool = false,
                              skipImages: Bool = false,
                              sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a.id == b.id, sourceLocation: sourceLocation)
    #expect(a.name == b.name, sourceLocation: sourceLocation)
    #expect(a.coordinates.latitude == b.coordinates.latitude, sourceLocation: sourceLocation)
    #expect(a.coordinates.longitude == b.coordinates.longitude, sourceLocation: sourceLocation)
    #expect(a.address == b.address, sourceLocation: sourceLocation)
    #expect(a.address2 == b.address2, sourceLocation: sourceLocation)
    #expect(a.icon == b.icon, sourceLocation: sourceLocation)
    #expect(a.rating == b.rating, sourceLocation: sourceLocation)
    // phone/email/url are JSON-encoded ContactItem strings; JSONEncoder key
    // order isn't guaranteed stable, so compare decoded values, not raw text.
    #expect(a.phone.compactMap(ContactItem.init(rawValue:)) == b.phone.compactMap(ContactItem.init(rawValue:)), sourceLocation: sourceLocation)
    #expect(a.email.compactMap(ContactItem.init(rawValue:)) == b.email.compactMap(ContactItem.init(rawValue:)), sourceLocation: sourceLocation)
    #expect(a.url.compactMap(ContactItem.init(rawValue:)) == b.url.compactMap(ContactItem.init(rawValue:)), sourceLocation: sourceLocation)
    #expect(a.notes == b.notes, sourceLocation: sourceLocation)
    #expect(a.applePlaceID == b.applePlaceID, sourceLocation: sourceLocation)
    #expect(a.appleNotFoundAt == b.appleNotFoundAt, sourceLocation: sourceLocation)
    #expect(a.createdAt == b.createdAt, sourceLocation: sourceLocation)
    #expect(a.updatedAt == b.updatedAt, sourceLocation: sourceLocation)
    #expect(a.deletedAt == b.deletedAt, sourceLocation: sourceLocation)
    if !skipImages {
        #expect(a.images == b.images, sourceLocation: sourceLocation)
    }
    if !skipRelationships {
        #expect(a.tags.map(\.id) == b.tags.map(\.id), sourceLocation: sourceLocation)
        #expect(a.category?.id == b.category?.id, sourceLocation: sourceLocation)
    }
}

public  func assertEqualCategory(_ a: Dropin.Category,
                              _ b: Dropin.Category,
                              sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a.id == b.id, sourceLocation: sourceLocation)
    #expect(a.name == b.name, sourceLocation: sourceLocation)
    #expect(a.color == b.color, sourceLocation: sourceLocation)
    #expect(a.icon == b.icon, sourceLocation: sourceLocation)
    #expect(a.createdAt == b.createdAt, sourceLocation: sourceLocation)
    #expect(a.updatedAt == b.updatedAt, sourceLocation: sourceLocation)
    #expect(a.deletedAt == b.deletedAt, sourceLocation: sourceLocation)
}

public  func assertEqualTag(_ a: Dropin.Tag,
                            _ b: Dropin.Tag,
                            sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a.id == b.id, sourceLocation: sourceLocation)
    #expect(a.name == b.name, sourceLocation: sourceLocation)
    #expect(a.color == b.color, sourceLocation: sourceLocation)
    #expect(a.createdAt == b.createdAt, sourceLocation: sourceLocation)
    #expect(a.updatedAt == b.updatedAt, sourceLocation: sourceLocation)
    #expect(a.deletedAt == b.deletedAt, sourceLocation: sourceLocation)
}

public  func assertEqualSpace(_ a: Space,
                              _ b: Space,
                              sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a.id == b.id, sourceLocation: sourceLocation)
    #expect(a.name == b.name, sourceLocation: sourceLocation)
    #expect(a.color == b.color, sourceLocation: sourceLocation)
    #expect(a.icon == b.icon, sourceLocation: sourceLocation)
    #expect(a.ownerId == b.ownerId, sourceLocation: sourceLocation)
    #expect(a.createdAt == b.createdAt, sourceLocation: sourceLocation)
    #expect(a.updatedAt == b.updatedAt, sourceLocation: sourceLocation)
    #expect(a.deletedAt == b.deletedAt, sourceLocation: sourceLocation)
}

public  func assertEqualProfile(_ a: Profile,
                                _ b: Profile,
                                sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a.id == b.id, sourceLocation: sourceLocation)
    #expect(a.email == b.email, sourceLocation: sourceLocation)
    #expect(a.displayName == b.displayName, sourceLocation: sourceLocation)
    #expect(a.plan == b.plan, sourceLocation: sourceLocation)
    #expect(a.createdAt == b.createdAt, sourceLocation: sourceLocation)
    #expect(a.updatedAt == b.updatedAt, sourceLocation: sourceLocation)
}
