//
//  IdentifiableURL.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/4/26.
//

import Foundation

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
