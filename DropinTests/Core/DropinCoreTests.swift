//
//  DropinDomainTests.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/4/26.
//

import Foundation
import Testing
import CoreLocation
import SwiftUI
@testable import Dropin

struct DropinCoreTests {
    
    @Test func testColorStuff() async throws {
        // Test string extension
        #expect("#111".isValidHexaColor)
        #expect("12F".isValidHexaColor)
        #expect("#1a2b3C".isValidHexaColor)
        #expect("F9e0D8".isValidHexaColor)
        #expect(!"#1a2b3".isValidHexaColor)
        #expect(!"F9e0D82".isValidHexaColor)
        #expect(!"QRTYIO".isValidHexaColor)
        // Test color conversion
        let c1 = Color(rgba: "#DA455F")
        let c1Resolved = c1.resolve(in: EnvironmentValues())
        #expect(abs(c1Resolved.red - 218 / 255) < 0.000001)
        #expect(abs(c1Resolved.green - 69 / 255) < 0.000001)
        #expect(abs(c1Resolved.blue - 95 / 255) < 0.000001)
        #expect(c1.hex == "#DA455F")

        let c2 = Color(rgba: "0AF")
        let c2Resolved = c2.resolve(in: EnvironmentValues())
        #expect(abs(c2Resolved.red - 0) < 0.000001)
        #expect(abs(c2Resolved.green - 170 / 255) < 0.000001)
        #expect(abs(c2Resolved.blue - 1) < 0.000001)
        #expect(c2.hex == "#00AAFF")
    }
    
    @Test func testLocationCoordinate2D() async throws {
        // Test CLLocationCoordinate2D extension
        let p1 = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        let p2 = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        let p3 = CLLocationCoordinate2D(latitude: 10, longitude: 50)
        #expect( p1.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == true )
        #expect( p2.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == false )
        #expect( p3.isInside(minLatitude: 0, maxLatitude: 15, minLongitude: 10, maxLongitude: 30) == false )
        // Test from string / to string
        let londonStrCoords = CLLocationCoordinate2D.london.formatted()
        #expect(CLLocationCoordinate2D(string: londonStrCoords) != nil)
        #expect(CLLocationCoordinate2D(string: "51.50986512, -0.11809234") != nil)
        #expect(CLLocationCoordinate2D(string: "51.509865  -0.118092") != nil)
        #expect(CLLocationCoordinate2D(string: "51,0") != nil)
    }
}
