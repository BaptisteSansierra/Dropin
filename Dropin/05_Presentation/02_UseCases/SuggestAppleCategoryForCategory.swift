//
//  SuggestAppleCategoryForCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/26.
//
//  Reverse of SuggestCategoryForAppleCategory: suggests an MKPointOfInterestCategory
//  whose (already-localized) display name plausibly matches a local category's name,
//  e.g. "Museums" ↔ "Museum". Lives here (not Domain) since MapKit isn't allowed there.
//
//  MKPointOfInterestCategory has no `allCases`/CaseIterable conformance, so this list
//  mirrors the cases already enumerated in MKPointOfInterestCategory+Extension's
//  displayName/icon/tint switches.
//

import MapKit

struct SuggestAppleCategoryForCategory {

    private static let allCategories: [MKPointOfInterestCategory] = [
        .airport, .amusementPark, .animalService, .aquarium, .atm, .automotiveRepair,
        .bakery, .bank, .baseball, .basketball, .beach, .beauty, .bowling, .brewery,
        .cafe, .campground, .carRental, .castle, .conventionCenter, .distillery,
        .evCharger, .fairground, .fireStation, .fishing, .fitnessCenter, .foodMarket,
        .fortress, .gasStation, .goKart, .golf, .hiking, .hospital, .hotel, .kayaking,
        .landmark, .laundry, .library, .mailbox, .marina, .miniGolf, .movieTheater,
        .museum, .musicVenue, .nationalMonument, .nationalPark, .nightlife, .park,
        .parking, .pharmacy, .planetarium, .police, .postOffice, .publicTransport,
        .restaurant, .restroom, .rockClimbing, .rvPark, .school, .skatePark, .skating,
        .skiing, .soccer, .spa, .stadium, .store, .surfing, .swimming, .tennis,
        .theater, .university, .volleyball, .winery, .zoo
    ]

    func callAsFunction(_ categoryName: String) -> MKPointOfInterestCategory? {
        let target = categoryName.lemmaNormalized
        guard !target.isEmpty else { return nil }
        return Self.allCategories.first { $0.displayName.lemmaNormalized == target }
    }
}
