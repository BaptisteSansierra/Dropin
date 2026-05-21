//
//  MapSettingsPreviewView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import SwiftUI
import MapKit

enum MapEditSettingsMode {
    case size
    case style
    case none
}

struct MapSettingsPreviewView: View {

    // MARK: States & Bindings
    @Binding private var mapEditMode: MapEditSettingsMode
    @Environment(AppSettings.self) private var appSettings

    // MARK: properties
    private var place: PlaceUI
    private var clusterPlace1: PlaceUI
    private var clusterPlace2: PlaceUI
    private var position: MapCameraPosition {
        MapCameraPosition.region(.abbeyRoad.offset(lat: -0.002))
    }
    
    // MARK: init
    init(mapEditMode: Binding<MapEditSettingsMode>) {
        self._mapEditMode = mapEditMode

        let group = GroupEntity(name: "", color: "#F0678A", icon: .sf("music.note"))
        let place = PlaceEntity(id: UUID(),
                                name: "Abbey Road",
                                coordinates: CLLocationCoordinate2D.abbeyRoad,
                                address: "",
                                tags: [],
                                group: group,
                                icon: .sf("pianokeys"))
        self.place = PlaceMapper.toUI(place)
        
        let group1 = GroupEntity(name: "", color: "#678AF0", icon: .sf("tag"))
        let cp1 = PlaceEntity(id: UUID(),
                              name: "Spot 1",
                              coordinates: .init(latitude: 51.54384339885454,
                                                 longitude: -0.14536248206413874),
                              address: "",
                              tags: [],
                              group: group1,
                              icon: nil)
        self.clusterPlace1 = PlaceMapper.toUI(cp1)
        
        let cp2 = PlaceEntity(id: UUID(),
                              name: "Spot 2",
                              coordinates: .init(latitude: 51.54395339885454,
                                                 longitude: -0.14586248206413874),
                              address: "",
                              tags: [],
                              group: nil,
                              icon: nil)
        self.clusterPlace2 = PlaceMapper.toUI(cp2)
    }
    
    // MARK: Body
    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
            overlayControls
                .opacity(mapEditMode == .none ? 0 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    // MARK: subviews
    var mapView: some View {

/*
 TODO: Replace by swiftMap by MKMap
 
        // Map with bottom inset for card
        PlacesMapViewVCRepresentable(viewModel: PlacesMapViewModel,
                                     places: places,
                                     selectedPlaceId: $selectedPlaceId,
                                     //topInset: 0,
                                     bottomInset: DropinApp.ui.mainTabBarHeight - UIApplication.rootBottomSafeArea())
*/

        Map(initialPosition: position, interactionModes: []) {
            annotation(place)
            annotation(clusterPlace1)
            annotation(clusterPlace2)
        }
    }
    
    private func annotation(_ place: PlaceUI) -> some MapContent {
        Annotation(place.name, coordinate: place.coordinates) {
            switch appSettings.pinStyle {
                case .rounded:
                    PlacePinAnnotationView(color: place.groupColor,
                                           icon: place.group?.icon,
                                           iconExtra: place.icon,
                                           size: appSettings.pinSize)
                case .rect:
                    VStack(spacing: 0) {
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon,
                                                size: appSettings.pinSize)
                        let rectHeight = PlaceRectAnnotationView.heightFor(size: appSettings.pinSize)
                        let arrrowHeight = appSettings.pinSize - rectHeight
                        BellCurveShape()
                            .fill(place.groupColor)
                            .frame(width: arrrowHeight * 3.33, height: arrrowHeight)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var overlayControls: some View {
        VStack(spacing: 0) {
            switch mapEditMode {
                case .size:
                    sizeSlider
                case .style:
                    styleButtons
                case .none:
                    EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .background(.ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 12))
        .padding(12)
    }

    private var sizeSlider: some View {
        HStack(spacing: 12) {
            @Bindable var appSettings = appSettings
            Image(systemName: "mappin")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Slider(value: $appSettings.pinSize,
                   in: AppSettings.pinSizeRange,
                   step: 1)
            Image(systemName: "mappin")
                .font(.system(size: 19))
                .foregroundStyle(.secondary)
            Text("\(Int(appSettings.pinSize))")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var styleButtons: some View {
        HStack(spacing: 10) {
            ForEach(PinStyle.allCases, id: \.id) { style in
                Button {
                    appSettings.pinStyle = style
                } label: {
                    HStack(spacing: 0) {
                        Spacer()
                        switch style {
                            case .rounded:
                                PlacePinAnnotationView(color: .blue,
                                                       icon: nil,
                                                       iconExtra: nil,
                                                       size: 25,
                                                       shadow: false)
                            case .rect:
                                PlaceRectAnnotationView(color: .blue,
                                                        icon: nil,
                                                        iconExtra: nil,
                                                        size: 25)
                        }
                        Spacer()
                        Text(style.displayName)
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 25)
                    .padding(.vertical, 10)
                    .background(appSettings.pinStyle == style
                                ? Color.accentColor.opacity(0.12)
                                : Color(.systemBackground).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                appSettings.pinStyle == style
                                ? Color.accentColor
                                : Color(.systemGray4),
                                lineWidth: appSettings.pinStyle == style ? 1.5 : 0.5
                            )
                    }
                }
                .foregroundStyle(
                    appSettings.pinStyle == style ? Color.accentColor : .primary
                )
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: appSettings.pinStyle)
            }
        }
    }

}

#Preview {
    @Previewable @State var mapEditMode = MapEditSettingsMode.style

    NavigationStack {
        MapSettingsPreviewView(mapEditMode: $mapEditMode)
            .environment(AppSettings())
    }
}
