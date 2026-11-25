//
//  String+Color.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/11/25.
//

import Foundation

extension String {

    /// Random hex color, same algorithm as `Color.random()` (mid-range
    /// channels by default so colors aren't too dark or too washed out).
    static func randomColor(range: ClosedRange<Double> = 0.25...0.8) -> String {
        func channel() -> Int {
            Int((Double.random(in: range) * 255).rounded())
        }
        return String(format: "#%02X%02X%02X", channel(), channel(), channel())
    }

    var isValidHexaColor: Bool {
        var hexa = self
        if hasPrefix("#") {
            let index = index(startIndex, offsetBy: 1)
            hexa = String(self[index...])
        }
        guard hexa.count == 3 || hexa.count == 6 else { return false }
        let validChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        if let _ = hexa.rangeOfCharacter(from: validChars.inverted) {
            return false
        }
        return true
    }
}

