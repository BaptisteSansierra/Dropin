//
//  Data_Mappers.swift
//  DropinTests
//
//  Round-trip tests for the Domain ↔ SwiftData and Domain ↔ UI mappers.
//
//  Goal: guarantee that every field declared on each entity is preserved
//  through `toData → toDomain` (and `toUI → toDomain`). Equatable on the
//  entities only compares by `id`, so the assertions here are explicitly
//  field-by-field. If you add a new property to an entity, add a matching
//  assertion here — otherwise the mapper could silently drop it.
//

import Foundation
import Testing
import CoreLocation
import ContactFieldKit
@testable import Dropin

// MARK: - Domain <-> SwiftData round-trip
@MainActor
struct Data_Mappers {

    @Test func placeRoundTrip() async throws {
        let original = SampleData.fullPlace()
        let sd = PlaceMapper.toData(original)
        // Relationships (tags/category/images) are intentionally not transferred
        // by toData (the repo wires SwiftData relationships afterward). Skip
        // them in the assert.
        let back = PlaceMapper.toDomain(sd, skipRelationships: true)
        assertEqualPlace(original, back, skipRelationships: true, skipImages: true)
    }

    @Test func groupRoundTrip() async throws {
        let original = SampleData.fullCategory()
        let sd = CategoryMapper.toData(original)
        let back = CategoryMapper.toDomain(sd)
        assertEqualCategory(original, back)
    }

    @Test func tagRoundTrip() async throws {
        let original = SampleData.fullTag()
        let sd = TagMapper.toData(original)
        let back = TagMapper.toDomain(sd)
        assertEqualTag(original, back)
    }

    @Test func profileRoundTrip() async throws {
        let original = SampleData.fullProfile()
        let sd = ProfileMapper.toData(original)
        let back = ProfileMapper.toDomain(sd)
        assertEqualProfile(original, back)
    }

    // Regression: server-originated `deletedAt` must survive a pull.
    // This is the specific bug that prompted these tests: if a place was
    // soft-deleted on device A, fresh-installed on device B's first pull
    // must preserve the deletedAt timestamp so the soft-deleted row stays
    // hidden instead of resurfacing.
    @Test func softDeletePreservedOnPull() async throws {
        // Place
        let p = SampleData.fullPlace()
        #expect(PlaceMapper.toDomain(PlaceMapper.toData(p), skipRelationships: true).deletedAt == p.deletedAt)
        // Group
        let g = SampleData.fullCategory()
        #expect(CategoryMapper.toDomain(CategoryMapper.toData(g)).deletedAt == g.deletedAt)
        // Tag
        let t = SampleData.fullTag()
        #expect(TagMapper.toDomain(TagMapper.toData(t)).deletedAt == t.deletedAt)
    }
}

