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
    var identifier: UUID
    var name: String
    var color: String  // hexadecimal value
    var icon: Icon
    var places: [SDPlace]
    var creationDate: Date

    init(identifier: UUID, name: String, color: String, icon: Icon, places: [SDPlace] = [SDPlace]()) {
        self.identifier = identifier
        self.name = name
        self.places = places
        self.icon = icon
        self.color = color
        self.creationDate = Date()
    }
}

#if DEBUG

extension SDGroup {  // Mock extension
    
    static func mockGroups() -> [SDGroup] {
        /*
        let g1 = SDGroup(identifier: UUID(), name: "Restaurant", color: "9944AA", icon: Icon("sf:fork.knife.circle"))
        let g2 = SDGroup(identifier: UUID(), name: "Bar", color: "CC22AA", icon: Icon("sf:wineglass"))
        let g3 = SDGroup(identifier: UUID(), name: "Trekking", color: "FF9999", icon: Icon("sf:figure.walk"))
        let g4 = SDGroup(identifier: UUID(), name: "Fishing spot", color: "456699", icon: Icon("sf:figure.fishing"))
        let g5 = SDGroup(identifier: UUID(), name: "Amusement", color: "DD8855", icon: Icon("sf:figure.play"))
        let g6 = SDGroup(identifier: UUID(), name: "Disco", color: "7788CC", icon: Icon("sf:opticaldisc"))
        let g7 = SDGroup(identifier: UUID(), name: "Culture", color: "2255DD", icon: Icon("sf:text.book.closed"))
        let g8 = SDGroup(identifier: UUID(), name: "Shop", color: "FF6600", icon: Icon("sf:cart"))
        let g9 = SDGroup(identifier: UUID(), name: "Body health", color: "4dd333", icon: Icon("sf:figure.mind.and.body"))
        let g10 = SDGroup(identifier: UUID(), name: "Laundry", color: "334dd3", icon: Icon("sf:tshirt"))
         */
        let g1 = SDGroup(identifier: UUID(), name: "Restaurant", color: "9944AA", icon: .sf("fork.knife.circle"))
        let g2 = SDGroup(identifier: UUID(), name: "Bar", color: "CC22AA", icon: .sf("wineglass"))
        let g3 = SDGroup(identifier: UUID(), name: "Trekking", color: "FF9999", icon: .sf("figure.walk"))
        let g4 = SDGroup(identifier: UUID(), name: "Fishing spot", color: "456699", icon: .sf("figure.fishing"))
        let g5 = SDGroup(identifier: UUID(), name: "Amusement", color: "DD8855", icon: .sf("figure.play"))
        let g6 = SDGroup(identifier: UUID(), name: "Disco", color: "7788CC", icon: .sf("opticaldisc"))
        let g7 = SDGroup(identifier: UUID(), name: "Culture", color: "2255DD", icon: .sf("text.book.closed"))
        let g8 = SDGroup(identifier: UUID(), name: "Shop", color: "FF6600", icon: .sf("cart"))
        let g9 = SDGroup(identifier: UUID(), name: "Body health", color: "4dd333", icon: .sf("figure.mind.and.body"))
        let g10 = SDGroup(identifier: UUID(), name: "Laundry", color: "334dd3", icon: .sf("tshirt"))
        return [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10]
    }
}

#endif
