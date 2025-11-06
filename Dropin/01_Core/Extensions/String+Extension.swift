//
//  String+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/11/25.
//

import Foundation

extension String {

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

