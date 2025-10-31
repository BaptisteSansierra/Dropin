//
//  SDGroup.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/7/25.
//

import Foundation
import SwiftData

@Model
final class SDGroup {
    var identifier: String
    var name: String
    var color: String  // hexadecimal value
    var sfSymbol: String
    var places: [SDPlace]
    var creationDate: Date

    init(identifier: String, name: String, color: String, sfSymbol: String, places: [SDPlace] = [SDPlace]()) {
        self.identifier = identifier
        self.name = name
        self.places = places
        self.sfSymbol = sfSymbol
        self.color = color
        self.creationDate = Date()
    }
}

#if DEBUG

extension SDGroup {  // Mock extension
    
    static func mockGroups() -> [SDGroup] {
        let g1 = SDGroup(identifier: UUID().uuidString, name: "Restaurant", color: "9944AA", sfSymbol: "fork.knife.circle")
        let g2 = SDGroup(identifier: UUID().uuidString, name: "Bar", color: "CC22AA", sfSymbol: "wineglass")
        let g3 = SDGroup(identifier: UUID().uuidString, name: "Trekking", color: "FF9999", sfSymbol: "figure.walk")
        let g4 = SDGroup(identifier: UUID().uuidString, name: "Fishing spot", color: "456699", sfSymbol: "figure.fishing")
        let g5 = SDGroup(identifier: UUID().uuidString, name: "Amusement", color: "DD8855", sfSymbol: "figure.play")
        let g6 = SDGroup(identifier: UUID().uuidString, name: "Disco", color: "7788CC", sfSymbol: "opticaldisc")
        let g7 = SDGroup(identifier: UUID().uuidString, name: "Culture", color: "2255DD", sfSymbol: "text.book.closed")
        let g8 = SDGroup(identifier: UUID().uuidString, name: "Shop", color: "FF6600", sfSymbol: "cart")
        let g9 = SDGroup(identifier: UUID().uuidString, name: "Body health", color: "4dd333", sfSymbol: "figure.mind.and.body")
        let g10 = SDGroup(identifier: UUID().uuidString, name: "Laundry", color: "334dd3", sfSymbol: "tshirt")
        return [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10]
    }
}

#endif
