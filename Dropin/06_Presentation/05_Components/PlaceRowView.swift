//
//  PlaceRowView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

/// Place representation as list row 
struct PlaceRowView: View {
    
    // MARK: - Dependencies
    @Environment(LocationManager.self) var locationManager
    
    // MARK: - private vars
    private var place: PlaceUI

    // MARK: - init
    init(place: PlaceUI) {
        self.place = place
    }

    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            PlaceAnnotationView(sysImage: place.systemImage,
                                color: place.groupColor)
                .padding(.trailing)
                .offset(x: 0, y: 5)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(place.name)
                        .font(.body)
                        .allowsHitTesting(true)
                    Spacer()
                    Text(locationManager.distanceStringTo(place.coordinates) ?? "")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(height: 40)
                    Text(place.address.isEmpty ? "" : place.address)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                ScrollView(.horizontal) {
                    LazyHStack {
                        let tags = place.tags.defaultSorted()
                        ForEach(tags) { tag in
                            TagView(name: tag.name, color: tag.color)
                        }
                    }
                }
            }
        }
    }
}


#if DEBUG
struct MockPlaceRowView: View {
    var mock: MockContainer
    @State var place1: PlaceUI
    @State var place2: PlaceUI

    var body: some View {
        List {
            PlaceRowView(place: place1)
                .listRowSeparator(.hidden)
            PlaceRowView(place: place2)
                .listRowSeparator(.hidden)
        }
        .environment(LocationManager())
        .listStyle(.grouped)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place1 = mock.getPlaceUI(0)
        self.place2 = mock.getPlaceUI(1)
    }
}

#Preview {
    NavigationStack {
        MockPlaceRowView()
    }
}

#endif
