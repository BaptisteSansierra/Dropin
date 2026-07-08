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
    @Environment(AppSettings.self) private var appSettings

    // MARK: - private properties
    private var settingsOpacity: CGFloat { settingsShown ? 1 : 0 }
    private var settingsOffsetY: CGFloat { settingsShown ? 0 : -20 }

    // MARK: - Init
    init(settingsShown: Binding<Bool>) {
        self._settingsShown = settingsShown
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
            let poiCaption = appSettings.mapSettings.hidePOI
                ? String(localized: "map.poi.show")
                : String(localized: "map.poi.hide")
            let sysImg = "mappin" // mapSettings.hidePointsOfInterest ? "mappin" : "mappin.slash"
            MapIcoButton(systemImage: sysImg,
                         imageFrame: CGSize(width: 15, height: 15),
                         rightCaption: poiCaption,
                         action: {
                appSettings.mapSettings.hidePOI.toggle()
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
            let mapModeCaption = appSettings.mapSettings.satellite
                ? String(localized: "map.mode.default")
                : String(localized: "map.mode.satellite")
            MapIcoButton(systemImage: "square.2.layers.3d",
                         imageFrame: CGSize(width: 15, height: 15),
                         rightCaption: mapModeCaption,
                         action: {
                appSettings.mapSettings.satellite.toggle()
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
    @Previewable @State var settingsShown: Bool = false
    
    MapSettingsOverlay(settingsShown: $settingsShown)
        .background(.brown)
        .environment(AppSettings())
}
