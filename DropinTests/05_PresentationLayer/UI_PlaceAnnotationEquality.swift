//
//  UI_PlaceAnnotationEquality.swift
//  DropinTests
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

@MainActor
struct UI_PlaceAnnotationEquality {

    private func makePlace(id: UUID = UUID(), updatedAt: Date) -> PlaceUIModel {
        PlaceUIModel(id: id,
                    name: "Test Place",
                    coordinates: .barcelona,
                    address: nil,
                    address2: nil,
                    tags: [],
                    createdAt: updatedAt,
                    updatedAt: updatedAt)
    }

    @Test func equalWhenIdAndUpdatedAtMatch() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: id, updatedAt: date))
        let b = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: id, updatedAt: date))
        #expect(a.isEqual(b))
        #expect(a.hash == b.hash)
    }

    @Test func notEqualWhenUpdatedAtDiffers() {
        let id = UUID()
        let a = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: id, updatedAt: Date(timeIntervalSince1970: 1_700_000_000)))
        let b = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: id, updatedAt: Date(timeIntervalSince1970: 1_700_000_500)))
        #expect(!a.isEqual(b))
    }

    @Test func notEqualWhenIdDiffers() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: UUID(), updatedAt: date))
        let b = MKPlacePromotedAnnotation(place: SampleData.makePlace(id: UUID(), updatedAt: date))
        #expect(!a.isEqual(b))
    }

    @Test func notEqualToDifferentType() {
        let a = MKPlacePromotedAnnotation(place: SampleData.makePlace(updatedAt: Date()))
        #expect(!a.isEqual("not an annotation"))
    }
}
