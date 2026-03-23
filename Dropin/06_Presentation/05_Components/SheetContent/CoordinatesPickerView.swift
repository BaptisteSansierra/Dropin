//
//  CoordinatesPickerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/3/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct CoordinatesPickerView: View {
        
    // MARK: - States & Bindings
    @Binding private var coords: CLLocationCoordinate2D
    @Binding private var address: String?
    @State private var loading: Bool = false
    @State private var tfCoords: String
    @State private var showInvalidAlert: Bool = false

    // MARK: - private properties
    private let onComplete: () -> Void

    // MARK: - init
    init(coords: Binding<CLLocationCoordinate2D>,
         address: Binding<String?>,
         onComplete: @escaping () -> Void) {
        self._coords = coords
        self._address = address
        self.onComplete = onComplete
        self.tfCoords = coords.wrappedValue.formatted()
    }
    
    // MARK: - body
    var body: some View {
        VStack(spacing: 0) {
            inputView
            addressView
            Spacer()
            MainButton(text: "create_place.create") {
                onComplete()
            }
            .padding(.bottom, 40)
        }
        .onChange(of: coords) { _, newValue in
            tfCoords = coords.formatted()
        }
    }

    // MARK: - subviews
    @ViewBuilder
    private var inputView: some View {
        Text("common.coordinates")
            .textStyle(.formSectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 5)
        
        TextField("common.coordinates", text: $tfCoords)
            .textStyle(.formSectionTitle2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .stroke(.gray, style: StrokeStyle(lineWidth: 0.5))
            }
            .padding(.horizontal)
            .onSubmit {
                submitCoords()
            }
    }
    
    private var addressView: some View {
        VStack(spacing: 0) {
            Text("common.address")
                .textStyle(.formSectionTitle)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 5)
            if let address = self.address {
                Text(address)
                    .textStyle(.formSectionTitle2)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .stroke(.gray, style: StrokeStyle(lineWidth: 0.5))
                    }
                    .padding(.horizontal)
                    .contextMenu {
                        Button(action: { copyAddressToClipboard() } ){
                            Text("common.copy_address")
                        }
                    }

            } else {
                ZStack {
                    Text("\n\n")
                        .textStyle(.formSectionTitle2)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                                .stroke(.gray, style: StrokeStyle(lineWidth: 0.5))
                        }
                        .padding(.horizontal)
                    ProgressView()
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - private methods
    private func submitCoords() {
        guard let tmpCoords = CLLocationCoordinate2D(string: tfCoords) else {
            showInvalidAlert = true
            tfCoords = coords.formatted()
            TODO
            return
        }
        coords = tmpCoords
    }
    
    private func copyAddressToClipboard() {
        guard let address = address else { return }
        UIPasteboard.general.string = address
    }
}

#Preview {
    @Previewable @State var presented: Bool = false
    @Previewable @State var coords = CLLocationCoordinate2D.barcelona
    @Previewable @State var address: String? = nil

    Map(initialPosition: .camera(.init(centerCoordinate: .barcelona, distance: 1000))) { }
    .onAppear {
        presented = true
    }
    .sheetOverlay(isPresented: $presented) {
        CoordinatesPickerView(coords: $coords,
                              address: $address,
                              onComplete: {
            print("complete")
        })
    }
}
