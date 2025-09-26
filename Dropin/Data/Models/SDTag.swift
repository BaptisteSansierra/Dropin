//
//  SDTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/7/25.
//

import Foundation
import SwiftData

@Model
final class SDTag {
    var name: String
    var colorHex: String
    var places: [SDPlace]?
    var creationDate: Date

    init(name: String, colorHex: String, places: [SDPlace] = [SDPlace]()) {
        self.creationDate = Date()
        self.name = name
        self.colorHex = colorHex
        self.places = places
    }
    
    #if DEBUG
    
    static let t1 = SDTag(name: "Clean restrooms", colorHex: "9944AA")
    static let t2 = SDTag(name: "Ugly restrooms", colorHex: "3388CC")
    static let t3 = SDTag(name: "Pizza", colorHex: "997766")
    static let t4 = SDTag(name: "Burger", colorHex: "7744AA")
    static let t5 = SDTag(name: "Salad", colorHex: "7744AA")
    static let t6 = SDTag(name: "Nature", colorHex: "FF4433")
    static let t7 = SDTag(name: "Kidz friendly", colorHex: "FF4433")
    static let t8 = SDTag(name: "Bad food", colorHex: "AA8855")
    static let t9 = SDTag(name: "5 ⭐️ ", colorHex: "AA5588")
    static let t10 = SDTag(name: "Healthy", colorHex: "AA44FF")
    static let t11 = SDTag(name: "Pasta", colorHex: "AAFF99")
    static let t12 = SDTag(name: "Rock", colorHex: "000000")
    static let t13 = SDTag(name: "Cool", colorHex: "449966")
    static let t14 = SDTag(name: "Take away", colorHex: "0054F8")
    static let t15 = SDTag(name: "Lavomatic", colorHex: "50A348")
    static let t16 = SDTag(name: "Eco", colorHex: "9045A3")

    static let all = [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]

    
    #endif
}
