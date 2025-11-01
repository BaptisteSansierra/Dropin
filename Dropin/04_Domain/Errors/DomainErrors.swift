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
        case missingName
        case notFound
    }
    enum Group: Error {
        case alreadyExists
        case missingName
        case undefinedMarker
        case notFound
    }
}

