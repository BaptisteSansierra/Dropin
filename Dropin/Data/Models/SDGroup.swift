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
    var name: String
    var locations: [SDPlace]
    var colorHex: String
    var creationDate: Date

    init(name: String, colorHex: String, locations: [SDPlace] = [SDPlace]()) {
        self.creationDate = Date()
        self.name = name
        self.colorHex = colorHex
        self.locations = locations
    }
    
#if DEBUG
    static let g1 = SDGroup(name: "Restaurant", colorHex: "9944AA")
    static let g2 = SDGroup(name: "Bar", colorHex: "CC22AA")
    static let g3 = SDGroup(name: "Trekking", colorHex: "FF9999")
    static let g4 = SDGroup(name: "Fishing spot", colorHex: "456699")
    static let g5 = SDGroup(name: "Amusement", colorHex: "DD8855")
    static let g6 = SDGroup(name: "Disco", colorHex: "7788CC")
    static let g7 = SDGroup(name: "Culture", colorHex: "2255DD")
    static let g8 = SDGroup(name: "Shop", colorHex: "FF6600")
    static let g9 = SDGroup(name: "Body health", colorHex: "4dd333")

    static let all = [g1, g2, g3, g4, g5, g6, g7, g8, g9]
    
#endif
}
