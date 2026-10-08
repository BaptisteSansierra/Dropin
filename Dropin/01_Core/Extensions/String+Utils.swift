//
//  String+Utils.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/6/26.
//

import Foundation

extension String {
    
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func initials() -> String {
        let elements = self.split(separator: " ")
        return elements.reduce("") { partialResult, substring in
            guard let first = substring.first else { return partialResult }
            return partialResult + String(first)
        }
        .uppercased()
    }
    
    func isValidEmail() -> Bool {
        guard let atIndex = self.firstIndex(of: "@") else { return false }
        let localPart = self[self.startIndex..<atIndex]
        let domainPart = self[self.index(after: atIndex)...]
        return !localPart.isEmpty && domainPart.contains(".") && !domainPart.hasPrefix(".") && !domainPart.hasSuffix(".")
    }
    
    func isValidPassword() -> Bool {
        guard self.count >= DropinApp.defaults.minimumPasswordLength else { return false }
        var hasLower = false, hasUpper = false, hasDigit = false, hasSymbol = false
        for scalar in self.unicodeScalars {
            if CharacterSet.lowercaseLetters.contains(scalar) { hasLower = true }
            else if CharacterSet.uppercaseLetters.contains(scalar) { hasUpper = true }
            else if CharacterSet.decimalDigits.contains(scalar) { hasDigit = true }
            else if !CharacterSet.whitespaces.contains(scalar) { hasSymbol = true }
        }
        return hasLower && hasUpper && hasDigit && hasSymbol
    }
}
