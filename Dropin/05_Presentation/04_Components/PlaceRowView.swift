//
//  PlaceRowView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

/// Place representation as list row 
struct PlaceRowView: View {
    
    // MARK: - States & Bindings
    @Environment(AppSettings.self) private var appSettings

    // MARK: - private vars
    private var place: PlaceUI
    private var locationManager: LocationManager

    // MARK: - init
    init(place: PlaceUI,
         locationManager: LocationManager) {
        self.place = place
        self.locationManager = locationManager
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 14)
                .fill(.surface1)
                .stroke(.fieldBorder)
            
            HStack(alignment: .top, spacing: 0) {
                switch appSettings.mapSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon)
                        .padding(.trailing)
                        .padding(.top, place.icon == nil ? 0 : 10)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.group?.icon,
                                               iconExtra: place.icon,
                                               shadow: false)
                        .padding(.trailing)
                        .padding(.top, place.icon == nil ? 0 : 10)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(place.name)
                            .textStyle(.cellTitle)
                            .allowsHitTesting(true)
                        Spacer()
                        Text(locationManager.distanceStringTo(place.coordinates) ?? "5.5km")
                            .textStyle(.cellDetail)
                    }
                    Text(place.address.isEmpty ? "" : place.address)
                        .textStyle(.cellSubtitle)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 5)
                    if place.tags.count > 0 {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                let tags = place.tags.defaultSorted()
                                ForEach(tags) { tag in
                                    TagView(name: tag.name, color: tag.color)
                                }
                            }
                            .padding(.vertical, 2) // add space for borders
                        }
                        .scrollIndicators(.hidden)
                        .padding(.top, 10)
                    }
                }
            }
            .padding(10)
        }
    }
}


#if DEBUG
struct MockPlaceRowView: View {
    var mock: MockContainer
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var place4: PlaceUI

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            //List {
            LazyVStack(spacing: 15) {
                PlaceRowView(place: place1,
                             locationManager: mock.locationManager)
                PlaceRowView(place: place2,
                             locationManager: mock.locationManager)
                PlaceRowView(place: place3,
                             locationManager: mock.locationManager)
                PlaceRowView(place: place4,
                             locationManager: mock.locationManager)
            }
            .padding(.horizontal)
            //.listStyle(.grouped)
        }

        
//        VStack(spacing: 0) {
//            PlaceRowView(place: place3,
//                         locationManager: mock.locationManager)
//                .border(.blue)
//                .listRowSeparator(.hidden)
//            PlaceRowView(place: place4,
//                         locationManager: mock.locationManager)
//                .border(.brown)
//                .listRowSeparator(.hidden)
//            Spacer()
//        }

    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place1 = mock.getPlaceUI(0)
        self.place2 = mock.getPlaceUI(1)
        self.place3 = mock.getPlaceUI(4)
        self.place4 = mock.getPlaceUI(5)
    }
}

#Preview {
    NavigationStack {
        MockPlaceRowView()
    }
    .environment(AppSettings())
    .environment(RootView.ActionBus())
}

#endif
