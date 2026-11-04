//
//  UI_Mappers.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/26.
//

import Foundation
import Testing
import CoreLocation
import ContactFieldKit
@testable import Dropin

// MARK: - Domain <-> UI round-trip
@MainActor
struct UI_Mappers {

    @Test func placeRoundTrip() async throws {
        let original = SampleData.fullPlace()
        let ui = PlaceMapper.toUI(original, skipRelationships: true)
        let back = PlaceMapper.toDomain(ui, skipRelationships: true)
        assertEqualPlace(original, back, skipRelationships: true)
    }

    @Test func groupRoundTrip() async throws {
        let original = SampleData.fullCategory()
        let ui = CategoryMapper.toUI(original)
        let back = CategoryMapper.toDomain(ui)
        // Color round-trips through SwiftUI.Color via hex — comparing the
        // hex form (Color → hex → Color → hex) keeps the test stable across
        // color-space rounding.
        #expect(original.id == back.id)
        #expect(original.name == back.name)
        #expect(original.color.uppercased() == back.color.uppercased())
        #expect(original.icon == back.icon)
        #expect(original.createdAt == back.createdAt)
        #expect(original.updatedAt == back.updatedAt)
        #expect(original.deletedAt == back.deletedAt)
    }

    @Test func tagRoundTrip() async throws {
        let original = SampleData.fullTag()
        let ui = TagMapper.toUI(original)
        let back = TagMapper.toDomain(ui)
        #expect(original.id == back.id)
        #expect(original.name == back.name)
        #expect(original.color.uppercased() == back.color.uppercased())
        #expect(original.createdAt == back.createdAt)
        #expect(original.updatedAt == back.updatedAt)
        #expect(original.deletedAt == back.deletedAt)
    }
}
