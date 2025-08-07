//
//  PlaceBubbleAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlaceBubbleAnnotationView: View {

    private var bubbleSize: CGFloat
    private var sysImage: String
    private var color: Color

    var body: some View {
        ZStack {
            Bubble()
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .fill(.white)
                .frame(width: bubbleSize, height: bubbleSize)
            Image(systemName: sysImage)
                //.scaledToFit()
                .offset(x: 0, y: -0.1 * bubbleSize)
        }
    }
    
    init(sysImage: String, size: CGFloat, color: Color = .dropinPrimary) {
        self.sysImage = sysImage
        self.bubbleSize = size
        self.color = color
    }
}

struct PlaceBubbleAnnotation: MapContent {
    
    @Environment(AppNavigationContext.self) private var navigationContext
    private var place: SDPlace

    var body: some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            let size: CGFloat = 40
            PlaceBubbleAnnotationView(sysImage: place.systemImage,
                                      size: size,
                                      color: place.groupColor)
                // Offset the whole thing so the bubble peak is centered where it shoul
                .offset(x: 0, y: -0.5 * size)
                .onTapGesture {
                    navigationContext.pinPlace = place
                }
                .border(.red, width: 3)
        }
        
        .annotationTitles(.hidden)
        Annotation(place.name, coordinate: place.coordinates) {
        }
        .annotationTitles(.visible)
    }
    
    init(place: SDPlace) {
        self.place = place
    }
}

#Preview {
    @Previewable @State var navigationContext = AppNavigationContext()
    Map {
        PlaceBubbleAnnotation(place: SDPlace.l1)
    }
//    .sheet(item: $navigationContext.pinPlace) { place in
//        Text("PLACE: \(place.name)")
//    }
    .environment(navigationContext)
}
