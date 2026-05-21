//
//  MKMapItem+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import MapKit
import Contacts

extension MKMapItem {
    
    private var poiIconMap: [MKPointOfInterestCategory: Icon] {
        [
            // Food & Drinks
            .bakery: .sf("birthday.cake"),
            .brewery: .fa("beer-mug-empty"),
            .cafe: .sf("cup.and.saucer"),
            .restaurant: .sf("fork.knife"),
            .winery: .sf("wineglass"),
            .foodMarket: .sf("basket"),
            .distillery: .fa("beer-mug-empty"),
            
            // Entertainment
            .movieTheater: .sf("film"),
            .nightlife: .fa("martini-glass-citrus"),
            .theater: .fa("masks-theater"),
            .amusementPark: .sf("figure.play"),
            .aquarium: .sf("water.waves"),
            .zoo: .fa("paw"),
            .bowling: .fa("bowling-ball"),
            .musicVenue: .sf("music.note"),
            .fairground: .sf("figure.play"),
            
            // Services
            .hospital: .sf("cross.case"),
            .pharmacy: .sf("stethoscope"),
            .police: .sf("exclamationmark.triangle"),
            .fireStation: .sf("exclamationmark.triangle"),
            .postOffice: .sf("envelope"),
            .mailbox: .sf("envelope"),
            .gasStation: .sf("fuelpump"),
            .evCharger: .sf("fuelpump"),
            .atm: .sf("banknote"),
            .bank: .sf("banknote"),
            .parking: .sf("parkingsign.circle"),
            .laundry: .sf("wrench.and.screwdriver"),
            .beauty: .sf("scissors"),
            .spa: .fa("spa"),
            .animalService: .fa("paw"),
            .automotiveRepair: .sf("wrench.and.screwdriver"),
            .restroom: .sf("figure.roll"),
            
            // Shopping
            .store: .sf("bag"),
            
            // Sports & Fitness
            .baseball: .sf("sportscourt"),
            .basketball: .sf("basketball"),
            .fitnessCenter: .sf("dumbbell"),
            .golf: .sf("figure.play"),
            .miniGolf: .sf("flag"),
            .hiking: .sf("figure.hiking"),
            .soccer: .sf("soccerball"),
            .stadium: .sf("sportscourt"),
            .tennis: .sf("tennisball"),
            .volleyball: .sf("volleyball"),
            .skating: .sf("figure.skating"),
            .skatePark: .sf("figure.skating"),
            .skiing: .sf("figure.play"),
            .rockClimbing: .sf("figure.climbing"),
            .swimming: .sf("figure.open.water.swim"),
            .surfing: .sf("water.waves"),
            .kayaking: .sf("water.waves"),
            .fishing: .sf("figure.fishing"),
            .goKart: .sf("car"),
            
            // Nature & Outdoors
            .nationalPark: .sf("tree"),
            .park: .sf("tree"),
            .campground: .sf("tent"),
            .beach: .sf("water.waves"),
            .marina: .sf("ferry"),
            .rvPark: .sf("tent.2"),
            
            // Culture & Education
            .museum: .sf("building.columns"),
            .library: .sf("book"),
            .school: .sf("graduationcap"),
            .university: .sf("graduationcap"),
            .planetarium: .sf("building.columns"),
            .landmark: .sf("building.2"),
            .nationalMonument: .sf("building.columns"),
            .fortress: .sf("building.2"),
            .castle: .sf("building.2"),
            .conventionCenter: .sf("building"),
            
            // Transport
            .airport: .sf("airplane"),
            .publicTransport: .sf("bus"),
            .carRental: .sf("car"),
            
            // Accommodation
            .hotel: .sf("bed.double")
        ]
    }
    
    func icon() -> Icon {
        let defaultIcon = Icon.sf("plus.circle")
        guard let category = pointOfInterestCategory else {
            return defaultIcon
        }
        return poiIconMap[category] ?? defaultIcon
    }
    
    /*
    func icon() -> Icon? {
        guard let category = pointOfInterestCategory else {
            return .sf("plus.circle")
        }
        
        switch category {
            // Food & Drinks
            case .bakery:
                return .sf("birthday.cake")
            case .brewery:
                return .fa("beer-mug-empty")
            case .cafe:
                return .sf("cup.and.saucer")
            case .restaurant:
                return .sf("fork.knife")
            case .winery:
                return .sf("wineglass")
            case .foodMarket:
                return .sf("basket")
            case .distillery:
                return .fa("beer-mug-empty")
                
            // Entertainment
            case .movieTheater:
                return .sf("film")
            case .nightlife:
                return .fa("martini-glass-citrus")
            case .theater:
                return .fa("masks-theater")
            case .amusementPark:
                return .sf("figure.play")
            case .aquarium:
                return .sf("water.waves")
            case .zoo:
                return .fa("paw")
            case .bowling:
                return .fa("bowling-ball")
            case .musicVenue:
                return .sf("music.note")
            case .fairground:
                return .sf("figure.play")
                
            // Services
            case .hospital:
                return .sf("cross.case")
            case .pharmacy:
                return .sf("stethoscope")
            case .police:
                return .sf("exclamationmark.triangle")
            case .fireStation:
                return .sf("exclamationmark.triangle")
            case .postOffice:
                return .sf("envelope")
            case .mailbox:
                return .sf("envelope")
            case .gasStation:
                return .sf("fuelpump")
            case .evCharger:
                return .sf("fuelpump")
            case .atm:
                return .sf("banknote")
            case .bank:
                return .sf("banknote")
            case .parking:
                return .sf("parkingsign.circle")
            case .laundry:
                return .sf("wrench.and.screwdriver")
            case .beauty:
                return .sf("scissors")
            case .spa:
                return .fa("spa")
            case .animalService:
                return .fa("paw")
            case .automotiveRepair:
                return .sf("wrench.and.screwdriver")
            case .restroom:
                return .sf("figure.roll")
                
            // Shopping
            case .store:
                return .sf("bag")
                
            // Sports & Fitness
            case .baseball:
                return .sf("sportscourt")
            case .basketball:
                return .sf("basketball")
            case .fitnessCenter:
                return .sf("dumbbell")
            case .golf:
                return .sf("figure.play")
            case .miniGolf:
                return .sf("flag")
            case .hiking:
                return .sf("figure.hiking")
            case .soccer:
                return .sf("soccerball")
            case .stadium:
                return .sf("sportscourt")
            case .tennis:
                return .sf("tennisball")
            case .volleyball:
                return .sf("volleyball")
            case .skating:
                return .sf("figure.skating")
            case .skatePark:
                return .sf("figure.skating")
            case .skiing:
                return .sf("figure.play")
            case .rockClimbing:
                return .sf("figure.climbing")
            case .swimming:
                return .sf("figure.open.water.swim")
            case .surfing:
                return .sf("water.waves")
            case .kayaking:
                return .sf("water.waves")
            case .fishing:
                return .sf("figure.fishing")
            case .goKart:
                return .sf("car")
                
            // Nature & Outdoors
            case .nationalPark:
                return .sf("tree")
            case .park:
                return .sf("tree")
            case .campground:
                return .sf("tent")
            case .beach:
                return .sf("water.waves")
            case .marina:
                return .sf("ferry")
            case .rvPark:
                return .sf("tent.2")
                
            // Culture & Education
            case .museum:
                return .sf("building.columns")
            case .library:
                return .sf("book")
            case .school:
                return .sf("graduationcap")
            case .university:
                return .sf("graduationcap")
            case .planetarium:
                return .sf("building.columns")
            case .landmark:
                return .sf("building.2")
            case .nationalMonument:
                return .sf("building.columns")
            case .fortress:
                return .sf("building.2")
            case .castle:
                return .sf("building.2")
            case .conventionCenter:
                return .sf("building")
                
            // Transport
            case .airport:
                return .sf("airplane")
            case .publicTransport:
                return .sf("bus")
            case .carRental:
                return .sf("car")
                
            // Accommodation
            case .hotel:
                return .sf("bed.double")
                
            default:
                return nil
        }
    }
     */
    
    
    func resolvedAddress() -> String? {
        if #available(iOS 26.0, *) {
            if let itemAddress = address {
                return itemAddress.fullAddress
            }
        } else {
            if let postalAddress = placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                return formatter.string(from: postalAddress)
            }
        }
        return nil
    }
    
    func resolvedCoordinates() -> CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            return location.coordinate
        } else {
            return placemark.coordinate
        }
    }
}
