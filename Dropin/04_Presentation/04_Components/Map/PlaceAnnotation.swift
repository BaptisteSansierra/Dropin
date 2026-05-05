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
    @Binding var place: PlaceUI
    @Environment(AppSettings.self) private var appSettings

    // MARK: - init
    init(place: Binding<PlaceUI>) {
        self._place = place
        self._selectedPlaceId = .constant(nil)
    }

    init(place: Binding<PlaceUI>, selectedPlaceId: Binding<UUID?>) {
        self._place = place
        self._selectedPlaceId = selectedPlaceId
    }

    // MARK: - Body
    var body: some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            VStack(spacing: 0) {
                switch appSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon)
                        let rectHeight = PlaceRectAnnotationView.heightFor(size: appSettings.pinSize)
                        let arrrowHeight = appSettings.pinSize - rectHeight
                        BellCurveShape()
                            .fill(place.groupColor)
                            .frame(width: arrrowHeight * 3.33, height: arrrowHeight)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.group?.icon,
                                               iconExtra: place.icon)
                }
            }
            //.offset(y: -DropinApp.ui.pinHeight * 0.5)
            .onTapGesture {
                selectedPlaceId = place.id
            }
        }
    }
}

#if DEBUG
struct MockPlaceAnnotation: View {
    var mock: MockContainer
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var place4: PlaceUI
    @State var place5: PlaceUI
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
        let group1 = mock.getGroupUI(0)
        let group2 = mock.getGroupUI(1)

        let place = mock.getPlaceUI()
        self.place1 = place
        self.place2 = place.copy()
        self.place3 = place.copy()
        self.place4 = place.copy()
        self.place5 = place.copy()

        self.place1.group = nil
        self.place2.group = group1
        self.place3.group = group2
        self.place4.group = nil
        self.place5.group = group2

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
