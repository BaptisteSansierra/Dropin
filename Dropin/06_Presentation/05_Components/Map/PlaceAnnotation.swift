//
//  PlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation
import ClusterMap


/// Draw a rounded bordered rectangle + SFSymbol as annotation
struct PlaceAnnotation: MapContent {
    
    // MARK: - State & Bindables
    @Binding var selectedPlaceId: UUID?
    @Binding var place: PlaceUI
    
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
            
            PlaceAnnotationView(color: place.groupColor,
                                icon: place.group?.icon,
                                iconExtra: place.icon)
            .onTapGesture {
                selectedPlaceId = place.id
            }
        }
    }
}

struct PlaceAnnotationView: View {

    private enum Style {
        case borderedRect
        case plainCircle // LEGACY
    }
    
    // MARK: - private vars
    private var style: Style = .borderedRect
    private var color: Color
    private var icon: Icon?
    private var iconExtra: Icon?
    private var size: CGFloat

    // MARK: - init
    init(color: Color = .dropinPrimary,
         icon: Icon? = nil,
         iconExtra: Icon? = nil,
         size: CGFloat = 36) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra
        self.size = size
    }

    // MARK: - Body
    var body: some View {

        switch style {
            case .plainCircle:
                // LEGACY
                ZStack {
                    Circle()
                        .fill(.backgroundPrimary)
                        .frame(width: size, height: size)
                    Circle()
                        .fill(color)
                        .frame(width: size * 30 / 36, height: size * 30 / 36)
                    if let icon = icon {
                        IconView(icon: icon)
                            .sizeXS()
                            .foregroundStyle(.backgroundPrimary)
                    }
                }
            case .borderedRect:
                ZStack {
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.backgroundPrimary)
                        .frame(width: size, height: size * 30 / 36)
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.backgroundPrimary)
                        .frame(width: size * 34 / 36, height: size * 28 / 36)
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.backgroundPrimary)
                        .frame(width: size * 32 / 36, height: size * 26 / 36)
                    if let icon = icon {
                        IconView(icon: icon)
                            .size(size * 18 / 36)
                    } else {
                        Image("empty")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.textPrimary.opacity(0.3))
                            .frame(width: size * 17 / 36, height: size * 17 / 36)
                    }
                }
                .overlay(content: {
                    if let iconExtra = iconExtra {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer()
                                PlaceIconView(icon: iconExtra, size: size * 20 / 36)
                            }
                            Spacer()
                        }
                        .offset(x: size * 12 / 36, y: size * -12 / 36)
                    }
                })
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
