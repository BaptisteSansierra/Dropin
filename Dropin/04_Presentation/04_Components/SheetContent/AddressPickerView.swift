//
//  AddressPickerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/3/26.
//

import SwiftUI
import CoreLocation
import MapKit
import SheetOverlay

struct AddressPickerView: View {
        
    // MARK: - States & Bindings
    @Binding private var coords: CLLocationCoordinate2D
    @Binding private var address: String?
    @State private var loading: Bool = false
    @State private var fetching: Bool = false
    @State private var addressViewOpacity: CGFloat = 0
    
    // MARK: - private properties
    //let onFetch: () -> Void
    let onComplete: () -> Void

    // MARK: - init
    init(coords: Binding<CLLocationCoordinate2D>,
         address: Binding<String?>,
         //onFetch: @escaping () -> Void,
         onComplete: @escaping () -> Void) {
        self._coords = coords
        self._address = address
        //self.onFetch = onFetch
        self.onComplete = onComplete
    }
    
    // MARK: - body
    var body: some View {
        ZStack() {
            
            VStack(spacing: 0) {
#if false
                coordinatesView
#endif
                addressView
                    .opacity(addressViewOpacity)
                Spacer()
            }
            actionsView
        }
        .onChange(of: fetching) { oldValue, newValue in
            guard oldValue != newValue else { return }
            withAnimation {
                addressViewOpacity = newValue ? 1 : 0
            }
        }
        .onChange(of: address) { _, newValue in
            guard let _ = newValue else {
                addressViewOpacity = 0
                fetching = false
                return
            }
        }
    }
    
    // MARK: - subviews
    @ViewBuilder
    var coordinatesView: some View {
        Text("common.coordinates")
            .textStyle(.formSectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 5)
        
        Text(verbatim: coords.formatted())
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
            .contextMenu {
                Button(action: { copyCoordinatesToClipboard() } ){
                    Text("common.copy_coordinates")
                }
            }
    }
    
    var addressView: some View {
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
                    Text(verbatim: "\n\n")
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
    
    var actionsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            SecondaryButton(text: "create_place.fetch", systemImage: "text.magnifyingglass") {
                fetching = true
            }
            .opacity(fetching ? 0 : 1)
            .animation(.easeInOut, value: fetching)
            
            Spacer()

            MainButton(text: "create_place.create") {
                onComplete()
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - private methods
    private func copyCoordinatesToClipboard() {
        UIPasteboard.general.string = coords.formatted()
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
        AddressPickerView(coords: $coords,
                          address: $address) {
            Log.debug("complete")
        }
        .sheetOverlayDetents([.height(DropinApp.ui.addressPickerSheetHeight)])
    }
}
