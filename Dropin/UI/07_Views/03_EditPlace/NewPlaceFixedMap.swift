//
//  NewPlaceFixedMap.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit

struct NewPlaceFixedMap: View {
    
    // MARK: - State & Bindings
    @State private var position: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 1000

    // MARK: - private vars
    private let cameraDistanceMax: Double = 100000000
    private let cameraDistanceMin: Double = 1
    private var place: SDPlace

    // MARK: - Body
    var body: some View {
        Map(position: $position, interactionModes: []) {
            Marker(place.name,
                   monogram: Text("common.new".uppercased()),
                   coordinate: place.coordinates)
        }
        .onFirstAppear {
            updateCamera()
        }
        .overlay {
            VStack {
                HStack {
                    Spacer()
                    MapIcoButton(systemImage: "plus.magnifyingglass",
                                 imageFrame: CGSize(width: 15, height: 15),
                                 color: (cameraDistance > cameraDistanceMin ? .dropinPrimary : .gray))
                        .padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 5))
                        .onTapGesture {
                            guard cameraDistance > cameraDistanceMin else { return }
                            cameraDistance = cameraDistance / 10
                            updateCamera()
                        }
                    MapIcoButton(systemImage: "minus.magnifyingglass",
                                 imageFrame: CGSize(width: 15, height: 15),
                                 color: (cameraDistance < cameraDistanceMax ? .dropinPrimary : .gray))
                        .padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 10))
                        .onTapGesture {
                            guard cameraDistance < cameraDistanceMax else { return }
                            cameraDistance = cameraDistance * 10
                            updateCamera()
                        }
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("\(place.coordinates.latitude) - \(place.coordinates.longitude) ")
                        .font(.caption)
                        .padding(4)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.55))
                        .cornerRadius(4)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10))
                }
            }
        }
        .frame(maxHeight: 250)

    }

    // MARK: - init
    init(place: SDPlace) {
        self.place = place
    }

    // MARK: - Actions
    private func updateCamera() {
        position = .camera(MapCamera(centerCoordinate: place.coordinates, distance: cameraDistance))
    }
}

#Preview {
    NewPlaceFixedMap(place: SDPlace.l1)
}
