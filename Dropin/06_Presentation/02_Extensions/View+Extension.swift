//
//  View+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/1/26.
//

import SwiftUI
import MapKit

extension View {
    
    // Allow assert to be called within a map content builder
    func assertionInMapContentBuilder(_ message: String) -> EmptyMapContent {
        assertionFailure(message)
        return EmptyMapContent()
    }
    
    // Allow assert to be called within a view builder
    func assertionInViewBuilder(_ message: String) -> EmptyView {
        assertionFailure(message)
        return EmptyView()
    }
    
    func commonErrorMessage(_ error: Error) -> String {
        switch error {
            case let urlError as URLError:
                switch urlError.code {
                    case .notConnectedToInternet:
                        return "No internet connection"
                    case .timedOut:
                        return "Request timed out, check your internet connection"
                    default:
                        return "URLError: \(urlError.code)"
                }

            case let nsError as NSError where nsError.domain == NSURLErrorDomain:
                return "NSURLDomainError: \(nsError.localizedDescription)"
            default:
                return "Unknown error: \(error.localizedDescription)"
        }
    }
}
