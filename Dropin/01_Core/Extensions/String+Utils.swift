//
//  String+Utils.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/6/26.
//

import Foundation

extension String {
    
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
        // TODO: improve password rules  
        self.count >= DropinApp.defaults.minimumPasswordLength
    }
}
