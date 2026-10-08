//
//  MKPointOfInterestCategory+Extension.swift
//  Dropin
//

import MapKit

extension MKPointOfInterestCategory {

    /// A localized display name for `MKPointOfInterestCategory`
    var displayName: String {
        switch self {
            case .atm:               return String(localized: LocalizedStringResource(stringLiteral: "poi_category.atm"))
            case .airport:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.airport"))
            case .amusementPark:     return String(localized: LocalizedStringResource(stringLiteral: "poi_category.amusement_park"))
            case .animalService:     return String(localized: LocalizedStringResource(stringLiteral: "poi_category.animal_service"))
            case .aquarium:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.aquarium"))
            case .automotiveRepair:  return String(localized: LocalizedStringResource(stringLiteral: "poi_category.automotive_repair"))
            case .bakery:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.bakery"))
            case .bank:              return String(localized: LocalizedStringResource(stringLiteral: "poi_category.bank"))
            case .baseball:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.baseball"))
            case .basketball:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.basketball"))
            case .beach:             return String(localized: LocalizedStringResource(stringLiteral: "poi_category.beach"))
            case .beauty:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.beauty"))
            case .bowling:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.bowling"))
            case .brewery:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.brewery"))
            case .cafe:              return String(localized: LocalizedStringResource(stringLiteral: "poi_category.cafe"))
            case .campground:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.campground"))
            case .carRental:         return String(localized: LocalizedStringResource(stringLiteral: "poi_category.car_rental"))
            case .castle:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.castle"))
            case .conventionCenter:  return String(localized: LocalizedStringResource(stringLiteral: "poi_category.convention_center"))
            case .distillery:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.distillery"))
            case .evCharger:         return String(localized: LocalizedStringResource(stringLiteral: "poi_category.ev_charger"))
            case .fairground:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.fairground"))
            case .fireStation:       return String(localized: LocalizedStringResource(stringLiteral: "poi_category.fire_station"))
            case .fishing:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.fishing"))
            case .fitnessCenter:     return String(localized: LocalizedStringResource(stringLiteral: "poi_category.fitness_center"))
            case .foodMarket:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.food_market"))
            case .fortress:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.fortress"))
            case .gasStation:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.gas_station"))
            case .goKart:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.go_kart"))
            case .golf:              return String(localized: LocalizedStringResource(stringLiteral: "poi_category.golf"))
            case .hiking:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.hiking"))
            case .hospital:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.hospital"))
            case .hotel:             return String(localized: LocalizedStringResource(stringLiteral: "poi_category.hotel"))
            case .kayaking:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.kayaking"))
            case .landmark:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.landmark"))
            case .laundry:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.laundry"))
            case .library:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.library"))
            case .mailbox:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.mailbox"))
            case .marina:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.marina"))
            case .miniGolf:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.mini_golf"))
            case .movieTheater:      return String(localized: LocalizedStringResource(stringLiteral: "poi_category.movie_theater"))
            case .museum:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.museum"))
            case .musicVenue:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.music_venue"))
            case .nationalMonument:  return String(localized: LocalizedStringResource(stringLiteral: "poi_category.national_monument"))
            case .nationalPark:      return String(localized: LocalizedStringResource(stringLiteral: "poi_category.national_park"))
            case .nightlife:         return String(localized: LocalizedStringResource(stringLiteral: "poi_category.nightlife"))
            case .park:              return String(localized: LocalizedStringResource(stringLiteral: "poi_category.park"))
            case .parking:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.parking"))
            case .pharmacy:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.pharmacy"))
            case .planetarium:       return String(localized: LocalizedStringResource(stringLiteral: "poi_category.planetarium"))
            case .police:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.police"))
            case .postOffice:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.post_office"))
            case .publicTransport:   return String(localized: LocalizedStringResource(stringLiteral: "poi_category.public_transport"))
            case .rvPark:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.rv_park"))
            case .restaurant:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.restaurant"))
            case .restroom:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.restroom"))
            case .rockClimbing:      return String(localized: LocalizedStringResource(stringLiteral: "poi_category.rock_climbing"))
            case .school:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.school"))
            case .skatePark:         return String(localized: LocalizedStringResource(stringLiteral: "poi_category.skate_park"))
            case .skating:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.skating"))
            case .skiing:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.skiing"))
            case .soccer:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.soccer"))
            case .spa:               return String(localized: LocalizedStringResource(stringLiteral: "poi_category.spa"))
            case .stadium:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.stadium"))
            case .store:             return String(localized: LocalizedStringResource(stringLiteral: "poi_category.store"))
            case .surfing:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.surfing"))
            case .swimming:          return String(localized: LocalizedStringResource(stringLiteral: "poi_category.swimming"))
            case .tennis:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.tennis"))
            case .theater:           return String(localized: LocalizedStringResource(stringLiteral: "poi_category.theater"))
            case .university:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.university"))
            case .volleyball:        return String(localized: LocalizedStringResource(stringLiteral: "poi_category.volleyball"))
            case .winery:            return String(localized: LocalizedStringResource(stringLiteral: "poi_category.winery"))
            case .zoo:               return String(localized: LocalizedStringResource(stringLiteral: "poi_category.zoo"))
            default:
                // Future OS adds a category before this file is updated — fall back to the raw identifier.
                return rawValue
        }
    }
    
    /// Icon for each category: SF Symbol where a good one exists, FontAwesome where it doesn't
    // (did not found any authoritative source to prefer SF-only from)
    var icon: Icon {
        switch self {
            // Food & Drinks
            case .bakery:           return .sf("birthday.cake")
            case .brewery:          return .fa("beer-mug-empty")
            case .cafe:             return .sf("cup.and.saucer")
            case .restaurant:       return .sf("fork.knife")
            case .winery:           return .sf("wineglass")
            case .foodMarket:       return .sf("basket")
            case .distillery:       return .fa("beer-mug-empty")

            // Entertainment
            case .movieTheater:     return .sf("film")
            case .nightlife:        return .fa("martini-glass-citrus")
            case .theater:          return .fa("masks-theater")
            case .amusementPark:    return .sf("figure.play")
            case .aquarium:         return .sf("water.waves")
            case .zoo:              return .fa("paw")
            case .bowling:          return .fa("bowling-ball")
            case .musicVenue:       return .sf("music.note")
            case .fairground:       return .sf("figure.play")

            // Services
            case .hospital:         return .sf("cross.case")
            case .pharmacy:         return .sf("stethoscope")
            case .police:           return .sf("exclamationmark.triangle")
            case .fireStation:      return .sf("exclamationmark.triangle")
            case .postOffice:       return .sf("envelope")
            case .mailbox:          return .sf("envelope")
            case .gasStation:       return .sf("fuelpump")
            case .evCharger:        return .sf("fuelpump")
            case .atm:              return .sf("banknote")
            case .bank:             return .sf("banknote")
            case .parking:          return .sf("parkingsign.circle")
            case .laundry:          return .sf("wrench.and.screwdriver")
            case .beauty:           return .sf("scissors")
            case .spa:              return .fa("spa")
            case .animalService:    return .fa("paw")
            case .automotiveRepair: return .sf("wrench.and.screwdriver")
            case .restroom:         return .sf("figure.roll")

            // Shopping
            case .store:            return .sf("bag")

            // Sports & Fitness
            case .baseball:         return .sf("sportscourt")
            case .basketball:       return .sf("basketball")
            case .fitnessCenter:    return .sf("dumbbell")
            case .golf:             return .sf("figure.play")
            case .miniGolf:         return .sf("flag")
            case .hiking:           return .sf("figure.hiking")
            case .soccer:           return .sf("soccerball")
            case .stadium:          return .sf("sportscourt")
            case .tennis:           return .sf("tennisball")
            case .volleyball:       return .sf("volleyball")
            case .skating:          return .sf("figure.skating")
            case .skatePark:        return .sf("figure.skating")
            case .skiing:           return .sf("figure.play")
            case .rockClimbing:     return .sf("figure.climbing")
            case .swimming:         return .sf("figure.open.water.swim")
            case .surfing:          return .sf("water.waves")
            case .kayaking:         return .sf("water.waves")
            case .fishing:          return .sf("figure.fishing")
            case .goKart:           return .sf("car")

            // Nature & Outdoors
            case .nationalPark:     return .sf("tree")
            case .park:             return .sf("tree")
            case .campground:       return .sf("tent")
            case .beach:            return .sf("water.waves")
            case .marina:           return .sf("ferry")
            case .rvPark:           return .sf("tent.2")

            // Culture & Education
            case .museum:           return .sf("building.columns")
            case .library:          return .sf("book")
            case .school:           return .sf("graduationcap")
            case .university:       return .sf("graduationcap")
            case .planetarium:      return .sf("building.columns")
            case .landmark:         return .sf("building.2")
            case .nationalMonument: return .sf("building.columns")
            case .fortress:         return .sf("building.2")
            case .castle:           return .sf("building.2")
            case .conventionCenter: return .sf("building")

            // Transport
            case .airport:          return .sf("airplane")
            case .publicTransport:  return .sf("bus")
            case .carRental:        return .sf("car")

            // Accommodation
            case .hotel:            return .sf("bed.double")

            default:
                // Future OS adds a category before this file is updated.
                return .sf("mappin")
        }
    }
}
