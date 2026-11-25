//
//  String+Utils.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/6/26.
//

import Foundation
import CoreLocation

extension String {

    var isTrimmedEmpty: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
    }

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
    
    func localized() -> String {
        String(localized: LocalizedStringResource(stringLiteral: self))
    }
    
    /// Extracts a coordinate from a Google Maps style URL string (`?q=lat,lon`).
    var coordinateFromGoogleMapsURL: CLLocationCoordinate2D? {
        guard let components = URLComponents(string: self),
              let q = components.queryItems?.first(where: { $0.name == "q" })?.value else {
            return nil
        }
        let parts = q.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2,
              let lat = parts[0], let lon = parts[1],
              (-90...90).contains(lat), (-180...180).contains(lon) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
