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
    static let g6 = SDGroup(name: "Voyage voyage", colorHex: "7788CC")
#endif
}
