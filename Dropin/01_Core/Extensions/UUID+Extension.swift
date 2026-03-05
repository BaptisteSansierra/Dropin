//
//  UUID+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import Foundation

extension UUID: @retroactive Identifiable {

    public var id: String { self.uuidString }
}
