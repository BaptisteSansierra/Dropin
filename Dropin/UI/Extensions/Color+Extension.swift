//
//  Color+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

extension Color {
    
    //func hexString(env: EnvironmentValues) -> String {
    var hex: String {
        @Environment(\.self) var env
        let resolved = self.resolve(in: env)
        let hexaStr = String(format: "#%02X%02X%02X", Int(resolved.red * 255), Int(resolved.green * 255), Int(resolved.blue * 255))
        print("RGB: \(resolved.red) \(resolved.green) \(resolved.blue) => \(hexaStr)")
        return hexaStr
    }

    static func random(range: ClosedRange<CGFloat> = CGFloat(0.25)...CGFloat(0.8)) -> Color {
        return Color(red: CGFloat.random(in: range),
                     green: CGFloat.random(in: range),
                     blue: CGFloat.random(in: range))
    }
    
    init(rgba: String) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var hex = rgba
        if rgba.hasPrefix("#") {
            let index = rgba.index(rgba.startIndex, offsetBy: 1)
            hex = String(rgba[index...])
        }
        let scanner = Scanner(string: hex)
        var hexValue: Int64 = 0
        guard scanner.scanHexInt64(&hexValue) else {
            print("Scan RGB hexa error, accepted formats are '#xxxxxx' or 'xxxxxx'")
            self.init(red: red, green: green, blue: blue, opacity: 1)
            return
        }
        if hex.count == 3 {
            red = CGFloat((hexValue & 0xF00) >> 16) * 17 / 255.0
            green = CGFloat((hexValue & 0x0F0) >> 8) * 17 / 255.0
            blue = CGFloat(hexValue & 0x00F) * 17 / 255.0
            self.init(red: red, green: green, blue: blue, opacity: 1)
        } else if hex.count == 6 {
            red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(hexValue & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue, opacity: 1)
        } else {
            print("Invalid RGB string, accepted formats are '#xxxxxx' or 'xxxxxx'", terminator: "")
            self.init(red: red, green: green, blue: blue, opacity: 1)
        }
    }
}
