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
}
