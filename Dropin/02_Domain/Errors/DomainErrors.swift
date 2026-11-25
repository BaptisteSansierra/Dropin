//
//  DomainErrors.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation

enum DomainError: Error {
    case notImplemented
    
    enum Place: Error {
        case alreadyExists
        case missingName
        case notFound
    }
    enum Tag: Error {
        case alreadyExists
        /// Another active tag has the same name (case-insensitive, surrounding whitespaces ignored)
        case nameAlreadyExists
        case missingName
        case invalidColor
        case notFound
    }
    enum Category: Error {
        case alreadyExists
        /// Another active category has the same name (case-insensitive, surrounding whitespaces ignored)
        case nameAlreadyExists
        case missingName
        //case undefinedMarker  // fixed by making Icon an enum
        case invalidColor
        case notFound
    }
    enum Image: Error {
        case invalidData
    }
}

