//
//  PlaceHeader.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
//
//struct PlaceHeader: View {
//    
//    private var place: SDPlace
//    
//    var body: some View {
//        HStack(alignment: .center) {
//            ZStack(alignment: .topLeading) {
//                PlaceAnnotationView(sysImage: place.systemImage,
//                                    color: place.groupColor)
//                .padding()
//                IcoButton(systemImage: "ellipsis", icoSize: 14)
//                    .padding(0)
//                    .onTapGesture {
//                        showingMarkerList.toggle()
//                    }
//            }
//            VStack(alignment: .leading) {
//                TextField("Give place a name", text: $place.name)
//                    .font(.title)
//                    .autocorrectionDisabled()
//                if !place.address.isEmpty {
//                    Text(place.address)
//                        .font(.callout)
//                        .foregroundStyle(.gray)
//                }
//            }
//        }
//
//    }
//}
