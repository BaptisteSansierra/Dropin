//
//  ApplePOIError.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

import Foundation

enum ApplePOIError: Error, Equatable {
    /// it seems the Apple POI was deleted Apple side
    case notFound
    /// server error when requesting apple POI
    case notConnected
    /// stored identifier is not recognized by apple... invalid ID ? that shouldn't happen
    case corrupted
    // Unexpected MK domain error
    case mkUnknown(UInt)
    // Unexpected error
    case unknown(Error)
    
    static func == (lhs: ApplePOIError, rhs: ApplePOIError) -> Bool {
        switch(lhs, rhs) {
            case (.notFound, .notFound):
                return true
            case (.notConnected, .notConnected):
                return true
            case (.corrupted, .corrupted):
                return true
            case (.mkUnknown, .mkUnknown):
                return true
            case (.unknown, .unknown):
                return true
            default:
                return false
        }
    }
}
