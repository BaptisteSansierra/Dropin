//
//  SampleData.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/26.
//

import Foundation
import Testing
import CoreLocation
import ContactFieldKit
@testable import Dropin

@MainActor
public enum SampleData {

    static func makePlace(id: UUID = UUID(),
                          name: String? = nil,
                          coordinates: CLLocationCoordinate2D = .barcelona,
                          applePlaceID: String? = nil,
                          updatedAt: Date? = nil,
                          deletedAt: Date? = nil) -> PlaceUIModel {
        let now = Date()
        return PlaceUIModel(id: id,
                            name: name ?? "",
                            coordinates: coordinates,
                            address: nil,
                            address2: nil,
                            tags: [],
                            applePlaceID: applePlaceID,
                            createdAt: now,
                            updatedAt: updatedAt ?? now,
                            deletedAt: deletedAt)
    }
    


    /// Distinct, non-default values for every field. Using fixed timestamps
    /// (rather than `Date()`) makes intermittent failures impossible.
    static let created = Date(timeIntervalSince1970: 1_700_000_000)
    static let updated = Date(timeIntervalSince1970: 1_700_000_500)
    static let deleted = Date(timeIntervalSince1970: 1_700_001_000)
    static let appleNotFound = Date(timeIntervalSince1970: 1_700_000_800)
    
    static func fullPlace(tags: [Dropin.Tag] = [], category: Dropin.Category? = nil) -> Place {
        let phones = [
            ContactItem(value: "0612345678", label: ContactLabel(kind: .phone, label: .mobile)).rawValue,
            ContactItem(value: "0123456789", label: ContactLabel(kind: .phone, label: .home)).rawValue,
        ]
        let emails = [
            ContactItem(value: "test@example.com", label: ContactLabel(kind: .email, label: .work)).rawValue,
        ]
        let urls = [
            ContactItem(value: "https://example.com", label: ContactLabel(kind: .url, label: .url)).rawValue,
        ]
        return Place(
            id: UUID(),
            name: "Sample Place",
            coordinates: CLLocationCoordinate2D(latitude: 41.4, longitude: 2.16),
            address: "Carrer X, 10",
            address2: "Apt 3B",
            tags: tags,
            category: category,
            images: [UUID(), UUID()],
            icon: .sf("fork.knife"),
            rating: 4.5,
            phone: phones,
            email: emails,
            url: urls,
            notes: "Some notes",
            applePlaceID: "apple-poi-12345",
            appleNotFoundAt: appleNotFound,
            createdAt: created,
            updatedAt: updated,
            deletedAt: deleted
        )
    }

    static func fullCategory() -> Dropin.Category {
        Dropin.Category(
            id: UUID(),
            name: "Sample Group",
            color: "#9944AA",
            icon: .sf("fork.knife.circle"),
            createdAt: created,
            updatedAt: updated,
            deletedAt: deleted
        )
    }

    static func fullTag() -> Dropin.Tag {
        Dropin.Tag(
            id: UUID(),
            name: "Sample Dropin.Tag",
            color: "#FF6600",
            createdAt: created,
            updatedAt: updated,
            deletedAt: deleted
        )
    }

    static func fullSpace() -> Space {
        Space(
            id: UUID(),
            name: "Sample Space",
            color: "#588B8B",
            icon: .sf("house"),
            ownerId: UUID(),
            createdAt: created,
            updatedAt: updated,
            deletedAt: deleted
        )
    }

    static func fullProfile() -> Profile {
        Profile(
            id: UUID(),
            email: "test@example.com",
            displayName: "Test User",
            plan: .free,
            createdAt: created,
            updatedAt: updated
        )
    }
}
