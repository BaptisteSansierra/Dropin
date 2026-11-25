//
//  StubApplePOIService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

#if DEBUG

import Foundation
import MapKit

@MainActor
final class StubApplePOIService: ApplePOIServiceProtocol {
    
    enum Behaviour {
        case fakeData
        case onlyUrl
        case onlyPhone
        case fakeNoData
        case throwError(ApplePOIError)
    }
    
    static var behaviour = Behaviour.fakeData
    
    func details(for id: String) async throws -> MKMapItem {
        try await details()
    }
    
    func details(for annotation: MKMapFeatureAnnotation) async throws -> MKMapItem {
        try await details()
    }
    
    private func details() async throws -> MKMapItem {
        let item = MKMapItem.forCurrentLocation()
        switch Self.behaviour {
            case .fakeData:
                item.phoneNumber = "*stub*data*"
                item.url = URL(string: "https://stub.applePOI.service")
            case .onlyUrl:
                item.url = URL(string: "https://stub.applePOI.service")
            case .onlyPhone:
                item.phoneNumber = "*stub*data*"
            case .fakeNoData:
                ()
            case .throwError(let error):
                throw error
        }
        return item
    }
}

#endif
