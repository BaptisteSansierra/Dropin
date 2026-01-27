//
//  MapSettingsOverlay.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI

/// Map display settings buttons 
struct MapSettingsOverlay: View {

    // MARK: - States & Bindings
    @Binding private var settingsShown: Bool
    @Binding private var hidePointsOfInterest: Bool
    @Binding private var satellite: Bool

    // MARK: - private properties
    private var settingsOpacity: CGFloat { settingsShown ? 1 : 0 }
    private var settingsOffsetY: CGFloat { settingsShown ? 0 : -20 }

    // MARK: - Init
    init(settingsShown: Binding<Bool>,
         hidePointsOfInterest: Binding<Bool>,
         satellite: Binding<Bool>) {
        self._settingsShown = settingsShown
        self._hidePointsOfInterest = hidePointsOfInterest
        self._satellite = satellite
    }

    // MARK: - Body
    var body: some View {
        VStack {
            gearButton
            poiButton
            modeButton
            Spacer()
        }
    }
    
    // MARK: - Subviews
    private var gearButton: some View {
        HStack {
            MapIcoButton(systemImage: "gear", action: { settingsShown.toggle() })
                .padding(EdgeInsets(top: 15, leading: 10, bottom: 0, trailing: 10))
            Spacer()
        }
    }

    private var poiButton: some View {
        HStack(alignment: .center) {
            // TODO: translate strings
            let poiCaption = hidePointsOfInterest ? "Show points of interest" : "Hide points of interest"
            let sysImg = "mappin" // mapSettings.hidePointsOfInterest ? "mappin" : "mappin.slash"
            MapIcoButton(systemImage: sysImg,
                         imageFrame: CGSize(width: 15, height: 15),
                         rightCaption: poiCaption,
                         action: {
                hidePointsOfInterest.toggle()
                settingsShown = false
            })
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                .offset(x: 0, y: settingsOffsetY)
                .opacity(settingsOpacity)
                .animation(.linear(duration: 0.2), value: settingsOpacity)
                .animation(.linear(duration: 0.2), value: settingsOffsetY)
            Spacer()
        }
    }
    
    private var modeButton: some View {
        HStack(alignment: .center) {
            // TODO: translate strings
            let mapModeCaption = satellite ? "Default" : "Satellite"
            MapIcoButton(systemImage: "square.2.layers.3d",
                         imageFrame: CGSize(width: 15, height: 15),
                         rightCaption: mapModeCaption,
                         action: {
                satellite.toggle()
                settingsShown = false
            })
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                .offset(x: 0, y: settingsOffsetY)
                .opacity(settingsOpacity)
                .animation(.linear(duration: 0.2), value: settingsOpacity)
                .animation(.linear(duration: 0.2), value: settingsOffsetY)
            Spacer()
        }
    }
}


#Preview {
    @Previewable @State var mapSettings = MapSettings()
    
    MapSettingsOverlay(settingsShown: $mapSettings.settingsShown,
                       hidePointsOfInterest: $mapSettings.hidePointsOfInterest,
                       satellite: $mapSettings.satellite)
        .background(.brown)
}
