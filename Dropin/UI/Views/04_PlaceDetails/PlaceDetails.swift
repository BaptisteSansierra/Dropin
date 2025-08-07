//
//  PlaceDetails.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct PlaceDetails: View {
    
    //private var place: SDPlace
    @Environment(SDPlace.self) var place
    
    @State private var showingDeleteWarning = false
    @State private var edit = false

    var body: some View {
        
        @Bindable var place = place
        
        VStack {
            ScrollView {
                HStack(alignment: .center) {
                    ZStack(alignment: .topLeading) {
                        PlaceAnnotationView(sysImage: place.systemImage,
                                            color: place.groupColor)
                        .padding()
                        IcoButton(systemImage: "ellipsis", icoSize: 14)
                            .padding(0)
                            .onTapGesture {
                                //showingMarkerList.toggle()
                            }
                    }
                    VStack(alignment: .leading) {
                        TextField("Give place a name", text: $place.name)
                            .font(.title)
                            .autocorrectionDisabled()
                            .disabled(!edit)
                        Text(place.address.isEmpty ? "" : place.address)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(EdgeInsets(top: 15,
                                    leading: 15,
                                    bottom: 15,
                                    trailing: 15))
                
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete place '\(place.name)' ?", isPresented: $showingDeleteWarning) {
            Button(role: .destructive) {
                print("NONONNOONNO")
            } label: {
                Text("Delete")
            }
            Button("Cancel", role: .cancel) { }
        }
    }
//    .alert("Delete this place ?", isPresented: $showingDeleteWarning, actions: { place in
//            Button(role: .destructive) {
//                print("NONONNOONNO")
//            } label: {
//                Text("Delete")
//            }
//            Button("Cancel", role: .cancel) { }
//    }) { place in
//        Text("You're about to delete '\(place.name)', this cannot be undone!")
//    }
    
//    init(place: SDPlace) {
//        self.place = place
//    }
}


#Preview {
    PlaceDetails()
        .environment(SDPlace.l1)
}
