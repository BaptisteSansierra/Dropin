//
//  Color+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

extension Color {
    
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
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
            Log.error("Scan RGB hexa error, accepted formats are '#xxxxxx' or 'xxxxxx'")
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
            Log.error("Invalid RGB string, accepted formats are '#xxxxxx' or 'xxxxxx'")
            self.init(red: red, green: green, blue: blue, opacity: 1)
        }
    }
    
    static func random(range: ClosedRange<CGFloat> = CGFloat(0.25)...CGFloat(0.8)) -> Color {
        return Color(red: CGFloat.random(in: range),
                     green: CGFloat.random(in: range),
                     blue: CGFloat.random(in: range))
    }
    
    var hex: String {
        //@Environment(\.self) var env
        //let resolved = self.resolve(in: env)
        let resolved = self.resolve(in: EnvironmentValues())
        var red = Int(resolved.red * 255)
        var green = Int(resolved.green * 255)
        var blue = Int(resolved.blue * 255)
        // Note: called with color from color picker, may give values out of [0, 1]
        // clamp them temporarilly, to be investigated
        red = red < 0 ? 0 : (red > 255 ? 255 : red)
        green = green < 0 ? 0 : (green > 255 ? 255 : green)
        blue = blue < 0 ? 0 : (blue > 255 ? 255 : blue)
        let hexaStr = String(format: "#%02X%02X%02X", red, green, blue)
        //print("RGB: \(resolved.red) \(resolved.green) \(resolved.blue) => \(hexaStr)")
        return hexaStr
    }
    
    func lighten(/*_ env: EnvironmentValues, */factor: Double) -> Color {
        let resolved = self.resolve(in: EnvironmentValues())
        let f = factor < 0 ? 0 : (factor > 1 ? 1 : factor)
        let redLightRange = Double(1 - resolved.red)
        let greenLightRange = Double(1 - resolved.green)
        let blueLightRange = Double(1 - resolved.blue)
        return Color(red: Double(resolved.red) + f * redLightRange,
                     green: Double(resolved.green) + f * greenLightRange,
                     blue: Double(resolved.blue) + f * blueLightRange,
                     opacity: Double(resolved.opacity))
    }

    func darken(factor: Double) -> Color {
        //@Environment(\.self) var env
        let resolved = self.resolve(in: EnvironmentValues())
        let f = factor < 0 ? 0 : (factor > 1 ? 1 : factor)
        return Color(red: Double(resolved.red) * (1 - f),
                     green: Double(resolved.green) * (1 - f),
                     blue: Double(resolved.blue) * (1 - f),
                     opacity: Double(resolved.opacity))
    }

    func luminance() -> CGFloat {
        guard let uiColor = UIColor(self).cgColor.components else { return 0 }
        let r = uiColor[0]
        let g = uiColor[1]
        let b = uiColor[2]
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance
    }

    func isDark() -> Bool {
        return luminance() < 0.5
    }
}
