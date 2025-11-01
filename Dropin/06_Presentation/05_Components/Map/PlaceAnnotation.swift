//
//  PlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation

/// Draw a rounded bordered rectangle + SFSymbol as annotation
struct PlaceAnnotation: MapContent {
    
    // MARK: - State & Bindables
    @Binding var selectedPlaceId: PlaceID?
    
    // MARK: - private vars
    private var place: PlaceUI
    
    // MARK: - Body
    var body: some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            
            PlaceAnnotationView(color: place.groupColor,
                                systemImage: place.group?.sfSymbol,
                                systemImageExtra: place.sfSymbol)
            .onTapGesture {
                selectedPlaceId = PlaceID(id: place.id)
            }
        }
    }
    
    // MARK: - init
    init(item: MapDisplayPlaceItem, selectedPlaceId: Binding<PlaceID?>) {
        self.place = item.place
        self._selectedPlaceId = selectedPlaceId
    }
    
    init(place: PlaceUI, selectedPlaceId: Binding<PlaceID?>) {
        self.place = place
        self._selectedPlaceId = selectedPlaceId
    }
}

struct PlaceAnnotationView: View {

    private enum Style {
        case borderedRect
        case plainCircle
    }
    
    // MARK: - private vars
    private var style: Style = .borderedRect
    private var color: Color
    private var systemImage: String?
    private var systemImageExtra: String?

    // MARK: - Body
    var body: some View {

        switch style {
            case .plainCircle:
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 36, height: 36)
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                    if let sfSymbol = systemImage {
                        Image(systemName: sfSymbol)
                            .foregroundStyle(.white)
                    }
                }
            case .borderedRect:
                ZStack {
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.white)
                        .frame(width: 36, height: 30)
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.white)
                        .frame(width: 34, height: 28)
                    RoundedRectangle(cornerSize: 5)
                        .stroke(color.opacity(0.2), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .fill(.white)
                        .frame(width: 32, height: 26)
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    } else {
                        Image(systemName: "questionmark.circle.dashed")
                    }
                }
                .overlay(content: {
                    if let systemImageExtra = systemImageExtra {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(.black)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: .black.opacity(0.5),
                                                radius: 3,
                                                x: -2, y: 2)
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 19, height: 19)
                                    Image(systemName: systemImageExtra)
                                        .font(.system(size: 10))
                                }
                            }
                            Spacer()
                        }
                        .offset(x: 12, y: -12)
                    }
                })
        }
    }
    
    // MARK: - init
    init(color: Color = .dropinPrimary,
         systemImage: String? = nil,
         systemImageExtra: String? = nil) {
        self.color = color
        self.systemImage = systemImage
        self.systemImageExtra = systemImageExtra
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
    @State var selectedPlaceId: PlaceID? = nil

    var body: some View {
        Map {
            PlaceAnnotation(place: place1, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: place2, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: place3, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: place4, selectedPlaceId: $selectedPlaceId)
            PlaceAnnotation(place: place5, selectedPlaceId: $selectedPlaceId)
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

        self.place2.sfSymbol = "duffle.bag"
        self.place3.sfSymbol = nil
        self.place4.sfSymbol = "figure.seated.side.left.airbag.on"
        self.place5.sfSymbol = "ivfluid.bag"

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
