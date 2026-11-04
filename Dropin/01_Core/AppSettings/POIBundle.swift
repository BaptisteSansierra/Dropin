//
//  POIBundle.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import Foundation
import MapKit

enum POIBundle: Int, Identifiable {
    
    // MARK: Cases
    case transport
    case nature
    case foodDrink
    case leisureSport
    case shopping
    case culture
    case health
    case lodging
    case services

    // MARK: static properties
    static let defaults: Set<POIBundle> = [.transport, .nature]

    // MARK: properties
    var id: Int { rawValue }
    
    var categories: [MKPointOfInterestCategory] {
        switch self {
            case .transport:
                return [.publicTransport, .airport, .parking, .evCharger, .gasStation, .carRental]
            case .foodDrink:
                return [.restaurant, .cafe, .bakery, .foodMarket, .brewery, .winery, .nightlife]
                     + ios18([.distillery])
            case .shopping:
                return [.store]
            case .culture:
                return [.museum, .theater, .library, .movieTheater]
                     + ios18([.musicVenue, .landmark, .nationalMonument, .castle, .fortress, .planetarium])
            case .nature:
                return [.park, .nationalPark, .beach, .campground, .marina]
                     + ios18([.rvPark, .hiking])
            case .leisureSport:
                return [.amusementPark, .aquarium, .zoo, .stadium, .fitnessCenter]
                     + ios18([.fairground, .bowling, .goKart, .miniGolf, .skatePark, .skating,
                              .baseball, .basketball, .soccer, .tennis, .volleyball, .golf,
                              .swimming, .rockClimbing, .skiing, .surfing, .kayaking, .fishing])
            case .health:
                return [.hospital, .pharmacy] + ios18([.spa, .beauty])
            case .lodging:
                return [.hotel]
            case .services:
                return [.atm, .bank, .postOffice, .police, .fireStation, .restroom, .laundry,
                        .school, .university]
                     + ios18([.mailbox, .animalService, .automotiveRepair, .conventionCenter])
        }
    }

    var symbol: String {
        switch self {
            case .transport:    return "tram.fill"
            case .foodDrink:    return "fork.knife"
            case .shopping:     return "bag.fill"
            case .culture:      return "building.columns.fill"
            case .nature:       return "leaf.fill"
            case .leisureSport: return "figure.run"
            case .health:       return "cross.case.fill"
            case .lodging:      return "bed.double.fill"
            case .services:     return "building.2.fill"
        }
    }

    var displayName: String {
        switch self {
            case .transport:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.transport"))
            case .nature:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.nature"))
            case .foodDrink:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.food_drink"))
            case .leisureSport:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.leisure_sport"))
            case .shopping:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.shopping"))
            case .culture:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.culture"))
            case .health:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.health"))
            case .lodging:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.lodging"))
            case .services:
                return String(localized: LocalizedStringResource(stringLiteral: "common.poi_bundle.services"))
        }
    }

    // MARK: static methods
    static func list(for selected: Set<POIBundle>) -> Set<MKPointOfInterestCategory> {
        Set(selected.flatMap({ $0.categories }))
    }

    static func filter(for selected: Set<POIBundle>) -> MKPointOfInterestFilter {
        selected.isEmpty ? .excludingAll
                         : MKPointOfInterestFilter(including: selected.flatMap(\.categories))
    }
    
    static var allCases: [POIBundle] {
        return [transport, nature, foodDrink, culture, leisureSport, shopping, health, lodging, services]
    }

    // MARK: private methods
    private func ios18(_ c: @autoclosure () -> [MKPointOfInterestCategory]) -> [MKPointOfInterestCategory] {
        if #available(iOS 18.0, *) { return c() } else { return [] }
    }
}
