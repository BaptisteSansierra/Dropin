//
//  ApplePOIDetails.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/26.
//

import Foundation

struct ApplePOIDetails: Identifiable, Equatable, Sendable {
    let id = UUID()
    let appleId: String?
    let phoneNumber: String?
    let url: URL?
}
