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
            
            PlaceAnnotationView(sysImage: place.systemImage,
                                color: place.groupColor)
            .onTapGesture {
                print("Set selected Pace to \(place.id)")
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
    private var sysImage: String
    private var color: Color

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
                    Image(systemName: sysImage)
                        .foregroundStyle(.white)
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
                    Image(systemName: sysImage)
                }
        }
    }
    
    // MARK: - init
    init(sysImage: String, color: Color = .dropinPrimary) {
        self.sysImage = sysImage
        self.color = color
    }
}

//#Preview {
//    @Previewable @State var selectedPlaceId: PlaceID? = nil
//    Map {
//        PlaceAnnotation(place: AppContainer.mock().mockPlaceUIExample(),
//                        selectedPlaceId: $selectedPlaceId )
//    }
//}
