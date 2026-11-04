//
//  Error+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation

extension Error {
    
    var isOffline: Bool {
        guard let urlError = self as? URLError else { return false }
        switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .dnsLookupFailed:
                return true
            case .internationalRoamingOff,
                 .dataNotAllowed:
                // the user’s cellular settings block it
                return true
            case .timedOut:
                // ambiguous. It can be a slow server rather than the user’s connection
                // See isTimeout
                return false
            case .cannotConnectToHost:
                // could mean the server is down
                return false
            default:
                return false
        }
    }
    
    var isTimeout: Bool {
        guard let urlError = self as? URLError else { return false }
        switch urlError.code {
            case .timedOut:
                return true
            default:
                return false
        }
    }
}
