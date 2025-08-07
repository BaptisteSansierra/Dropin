//
//  MapSettingsOverlay.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI

struct MapSettingsOverlay: View {
    
    @Environment(MapSettings.self) var mapSettings
    
    var body: some View {
        
        VStack {
            HStack {
                MapIcoButton(systemImage: "gear")
                    .padding(EdgeInsets(top: 15, leading: 10, bottom: 0, trailing: 10))
                    .onTapGesture {
                        mapSettings.settingsShown.toggle()
                    }
                Spacer()
            }
            HStack(alignment: .center) {
                let poiCaption = mapSettings.hidePointsOfInterest ? "Show points of interest" : "Hide points of interest"
                let sysImg = "mappin" // mapSettings.hidePointsOfInterest ? "mappin" : "mappin.slash"
                MapIcoButton(systemImage: sysImg,
                             imageFrame: CGSize(width: 15, height: 15),
                             rightCaption: poiCaption)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                    .onTapGesture {
                        mapSettings.hidePointsOfInterest.toggle()
                        mapSettings.settingsShown = false
                    }
                    .offset(x: 0, y: mapSettings.settingsOffsetY)
                    .opacity(mapSettings.settingsOpacity)
                    .animation(.linear(duration: 0.2), value: mapSettings.settingsOpacity)
                    .animation(.linear(duration: 0.2), value: mapSettings.settingsOffsetY)
                Spacer()
            }

            HStack(alignment: .center) {
                let mapModeCaption = mapSettings.satellite ? "Default" : "Satellite"
                MapIcoButton(systemImage: "square.2.layers.3d",
                             imageFrame: CGSize(width: 15, height: 15),
                             rightCaption: mapModeCaption)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                    .onTapGesture {
                        mapSettings.satellite.toggle()
                        mapSettings.settingsShown = false
                    }
                    .offset(x: 0, y: mapSettings.settingsOffsetY)
                    .opacity(mapSettings.settingsOpacity)
                    .animation(.linear(duration: 0.2), value: mapSettings.settingsOpacity)
                    .animation(.linear(duration: 0.2), value: mapSettings.settingsOffsetY)

                Spacer()
            }
            Spacer()
        }
    }
}


#Preview {
    MapSettingsOverlay()
        .environment(MapSettings())
        .background(.brown)
}
