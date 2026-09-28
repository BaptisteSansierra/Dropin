//
//  PlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlaceAnnotation: MapContent {
    
    // MARK: - State & Bindables
    @Binding var selectedPlaceId: UUID?
    @Binding var place: PlaceUIModel
    @Environment(AppSettings.self) private var appSettings

    // MARK: - init
    init(place: Binding<PlaceUIModel>) {
        self._place = place
        self._selectedPlaceId = .constant(nil)
    }

    init(place: Binding<PlaceUIModel>, selectedPlaceId: Binding<UUID?>) {
        self._place = place
        self._selectedPlaceId = selectedPlaceId
    }

    // MARK: - Body
    var body: some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            VStack(spacing: 0) {
                switch appSettings.mapSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.category?.icon,
                                                iconExtra: place.icon)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.category?.icon,
                                               iconExtra: place.icon)
                }
            }
            .onTapGesture {
                selectedPlaceId = place.id
            }
        }
    }
}

#if DEBUG
struct MockPlaceAnnotation: View {
    var mock: MockContainer
    @State var place1: PlaceUIModel
    @State var place2: PlaceUIModel
    @State var place3: PlaceUIModel
    @State var place4: PlaceUIModel
    @State var place5: PlaceUIModel
    @State var selectedPlaceId: UUID? = nil

    var body: some View {
        Map {
            PlaceAnnotation(place: $place1, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: $place2, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: $place3, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: $place4, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: $place5, selectedPlaceId: $selectedPlaceId)
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        let group1 = mock.getCategoryUIModel(0)
        let group2 = mock.getCategoryUIModel(1)

        let place = mock.getPlaceUIModel()
        self.place1 = place
        self.place2 = place.copy()
        self.place3 = place.copy()
        self.place4 = place.copy()
        self.place5 = place.copy()

        self.place1.category = nil
        self.place2.category = group1
        self.place3.category = group2
        self.place4.category = nil
        self.place5.category = group2

        self.place2.icon = .sf("duffle.bag")
        self.place3.icon = nil
        self.place4.icon = .sf("figure.seated.side.left.airbag.on")
        self.place5.icon = .sf("ivfluid.bag")

        self.place2.coordinates = place.coordinates.offset(x: 0, y: 0.05)
        self.place3.coordinates = place.coordinates.offset(x: 0.05, y: 0)
        self.place4.coordinates = place.coordinates.offset(x: 0.05, y: 0.05)
        self.place5.coordinates = place.coordinates.offset(x: 0.025, y: 0.025)
    }
}

#Preview {
    MockPlaceAnnotation()
}
#endif
