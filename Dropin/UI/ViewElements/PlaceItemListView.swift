//
//  PlaceItemListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

struct PlaceItemListView: View {
    
    @Environment(LocationManager.self) var locationManager
    
    var place: SDPlace
    
    var body: some View {
        HStack(alignment: .top) {
            PlaceAnnotationView(sysImage: place.systemImage,
                                color: place.groupColor)
                .padding(.trailing)
                .offset(x: 0, y: 5)
            VStack(alignment: .leading) {
                HStack {
                    Text(place.name)
                        .font(.body)
                        .allowsHitTesting(true)
                    Spacer()
                    Text(locationManager.distanceStringTo(place.coordinates) ?? "")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Text(place.address.isEmpty ? "" : place.address)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    //.lineLimit(4, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(place.sortedTags()) { tag in
                            TagView(name: tag.name,
                                    color: Color(rgba: tag.colorHex))
                        }
                    }
                }
                #if DEBUG
//                .frame(maxHeight: 40)
                #endif
            }
        }
        //.background(.red)
    }
    
    init(place: SDPlace) {
        self.place = place
    }
}

#Preview {
    List {
        PlaceItemListView(place: SDPlace.l1)
            .listRowSeparator(.hidden)
//            .listRowBackground(
//                RoundedRectangle(cornerRadius: 5)
//                    .background(.clear)
//                    .foregroundColor(.red)
//                    .padding(
//                        EdgeInsets(
//                            top: 2,
//                            leading: 10,
//                            bottom: 2,
//                            trailing: 10
//                        )
//                    )
//            )
        PlaceItemListView(place: SDPlace.l2)
            .listRowSeparator(.hidden)
//            .listRowBackground(
//                RoundedRectangle(cornerRadius: 5)
//                    .background(.clear)
//                    .foregroundColor(.white)
//                    .padding(
//                        EdgeInsets(
//                            top: 10,
//                            leading: 10,
//                            bottom: 0,
//                            trailing: 10
//                        )
//                    )
//                    .shadow(radius: 5)
//            )
    }
    .environment(LocationManager())
    //.listStyle(.plain)
    .listStyle(.grouped)
}
