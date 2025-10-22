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
    private var place: SDPlace

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
                        ForEach(place.sortedTags()) { tag in
                            TagView(name: tag.name,
                                    color: Color(rgba: tag.color))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - init
    init(place: SDPlace) {
        self.place = place
    }
}

#if DEBUG
#Preview {
    List {
        PlaceRowView(place: SDPlace.l1)
            .listRowSeparator(.hidden)
        PlaceRowView(place: SDPlace.l2)
            .listRowSeparator(.hidden)
    }
    .environment(LocationManager())
    .listStyle(.grouped)
}
#endif
