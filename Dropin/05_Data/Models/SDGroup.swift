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
    var places: [SDPlace]
    var color: String  // hexadecimal value
    var creationDate: Date
    
    init(identifier: String, name: String, color: String, places: [SDPlace] = [SDPlace]()) {
        self.identifier = identifier
        self.creationDate = Date()
        self.name = name
        self.color = color
        self.places = places
    }
}

#if DEBUG

extension SDGroup {  // Mock extension
    
    static func mockGroups() -> [SDGroup] {
        let g1 = SDGroup(identifier: UUID().uuidString, name: "Restaurant", color: "9944AA")
        let g2 = SDGroup(identifier: UUID().uuidString, name: "Bar", color: "CC22AA")
        let g3 = SDGroup(identifier: UUID().uuidString, name: "Trekking", color: "FF9999")
        let g4 = SDGroup(identifier: UUID().uuidString, name: "Fishing spot", color: "456699")
        let g5 = SDGroup(identifier: UUID().uuidString, name: "Amusement", color: "DD8855")
        let g6 = SDGroup(identifier: UUID().uuidString, name: "Disco", color: "7788CC")
        let g7 = SDGroup(identifier: UUID().uuidString, name: "Culture", color: "2255DD")
        let g8 = SDGroup(identifier: UUID().uuidString, name: "Shop", color: "FF6600")
        let g9 = SDGroup(identifier: UUID().uuidString, name: "Body health", color: "4dd333")
        let g10 = SDGroup(identifier: UUID().uuidString, name: "Laundry", color: "334dd3")
        return [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10]
    }
}

#endif
