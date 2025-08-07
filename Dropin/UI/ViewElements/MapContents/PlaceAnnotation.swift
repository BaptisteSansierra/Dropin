//
//  PlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlaceAnnotationView: View {

    enum Style {
        case borderedRect
        case plainCircle
    }
    
    private var style: Style = .borderedRect
    private var sysImage: String
    private var color: Color

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
//                    RoundedRectangle(cornerSize: 5)
//                        .fill(color.opacity(0.08))
//                        .frame(width: 36, height: 30)
                    Image(systemName: sysImage)
                }
        }
    }
    
    init(sysImage: String, color: Color = .dropinPrimary) {
        self.sysImage = sysImage
        self.color = color
    }
}

struct PlaceAnnotation: MapContent {
    
    @Environment(AppNavigationContext.self) private var navigationContext
    private var place: SDPlace

    var body: some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            PlaceAnnotationView(sysImage: place.systemImage,
                                color: place.groupColor)
                .onTapGesture {
                    navigationContext.pinPlace = place
                }
        }
    }
    
    init(place: SDPlace) {
        self.place = place
    }
}

#Preview {
    @Previewable @State var navigationContext = AppNavigationContext()
    Map {
        PlaceAnnotation(place: SDPlace.l1)
    }
    .sheet(item: $navigationContext.pinPlace) { place in
        Text("PLACE: \(place.name)")
            .presentationDetents([.fraction(0.25)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)

    }
    .environment(navigationContext)
}
