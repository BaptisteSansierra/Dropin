//
//  Domain_Import.swift
//  DropinTests
//
//  Created by baptiste sansierra on 23/11/26.
//

import Foundation

import Testing
import Foundation
@testable import Dropin

struct Domain_Import {
    
    @MainActor
    @Test func testImportStructs() async throws {
        
        #expect(Set(ImportSource.dropin.matchingExtensions) == Set([.dropin]))
        #expect(Set(ImportSource.mapstr.matchingExtensions) == Set([.geojson]))
        #expect(Set(ImportSource.google.matchingExtensions) == Set([.geojson, .json]))

        #expect(Set(ImportSupportedExtension.dropin.matchingSource) == Set([.dropin]))
        #expect(Set(ImportSupportedExtension.geojson.matchingSource) == Set([.mapstr, .google, .unknown]))
        #expect(Set(ImportSupportedExtension.json.matchingSource) == Set([.google, .unknown]))
    }
}
