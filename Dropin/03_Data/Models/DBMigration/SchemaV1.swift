//
//  SchemaV1.swift
//  Dropin
//
//  Created by baptiste sansierra on 28/10/26.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {

    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [PlaceRecord.self,
         TagRecord.self,
         CategoryRecord.self,
         PlaceImageRecord.self,
         ProfileRecord.self,
         SpaceRecord.self]
    }
}

