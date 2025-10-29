//
//  PlaceSmallAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlaceSmallAnnotation: MapContent {
    
    // MARK: - private vars
    private var place: PlaceUI
    
    // MARK: - Body
    var body: some MapContent {
        Annotation("", coordinate: place.coordinates) {
            PlaceSmallAnnotationView(color: place.groupColor)
        }
    }
    
    // MARK: - init
    init(item: MapDisplayPlaceItem) {
        self.place = item.place
    }
    
    init(place: PlaceUI) {
        self.place = place
    }
}

struct PlaceSmallAnnotationView: View {
    
    // MARK: - private vars
    private var color: Color

    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 16, height: 16)
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
    }
    
    // MARK: - init
    init(color: Color = .dropinPrimary) {
        self.color = color
    }
}

#if DEBUG
struct MockPlaceSmallAnnotation: View {
    var mock: MockContainer
    @State var places: [PlaceUI]

    var body: some View {
        Map {
            ForEach(places) { place in
                PlaceSmallAnnotation(place: place)
            }
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUI()
    }
}

#Preview {
    MockPlaceSmallAnnotation()
}

#endif
