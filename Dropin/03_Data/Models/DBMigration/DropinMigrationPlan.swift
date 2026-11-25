//
//  DropinMigrationPlan.swift
//  Dropin
//
//  Created by baptiste sansierra on 28/10/26.
//

import SwiftData

enum DropinMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] } // nothing to migrate yet
}
