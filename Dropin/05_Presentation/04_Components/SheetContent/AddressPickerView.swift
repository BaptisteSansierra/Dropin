//
//  AddressPickerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/3/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct AddressPickerView: View {
        
    // MARK: - States & Bindings
    @Binding private var coords: CLLocationCoordinate2D
    @Binding private var address: String?
    @Binding private var fetching: Bool
    @Binding private var isPresented: Bool
    @State private var tfCoords: String
    @State private var showInvalidAlert: Bool = false
    @State private var addressViewOpacity: CGFloat = 0
    @State private var editCoords: Bool
    
    // MARK: - private properties
    private let onCoordsEdit: (CLLocationCoordinate2D) -> Void
    private let onComplete: () -> Void
    //private var editCoords: Bool

    // MARK: - init
    init(editCoords: Bool,
         coords: Binding<CLLocationCoordinate2D>,
         address: Binding<String?>,
         fetching: Binding<Bool>,
         isPresented: Binding<Bool>,
         onCoordsEdit: @escaping (CLLocationCoordinate2D) -> Void,
         onComplete: @escaping () -> Void) {
        //self._editCoords = State(initialValue: editCoords)
        self._editCoords = State(wrappedValue: editCoords)
        self.editCoords = editCoords
        self._coords = coords
        self._address = address
        self._fetching = fetching
        self._isPresented = isPresented
        self.onCoordsEdit = onCoordsEdit
        self.onComplete = onComplete
        self.tfCoords = coords.wrappedValue.formatted()
    }
    
    // MARK: - body
    var body: some View {
        VStack(spacing: 0) {
            
            headerView
                .padding(.top, 30)

            
            if editCoords {
//                coordsView
//                    .padding(.top, editCoords ? 20 : 0)
//                    .padding(.bottom, editCoords ? 5 : 0)
//                    .opacity(editCoords ? 1 : 0.1)
//                    .if(!editCoords) { v in
//                        v.frame(height: 1)
//                    }
//                    .clipped()

                coordsView
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                    .opacity(1)
            }
             
            addressView
                .padding(.top)
            if !editCoords {
                coordsInfoView
                    .padding(.top, 20)
                    //.opacity(editCoords ? 0 : 1)
            }
            Spacer()
            MainButton(text: "common.continue") {
                onComplete()
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal)
        .onChange(of: coords) { _, newValue in
            tfCoords = coords.formatted()
        }
        .alertOk(isPresented: $showInvalidAlert,
                 title: "alert.invalid_coords.title",
                 body: "alert.invalid_coords.body")
    }

    // MARK: - subviews
    private var headerView: some View {
        HStack {
            Text("common.new_place")
                .textStyle(.title2)
            Spacer()
            TextButton(text: "common.cancel",
                       action: dismiss)
        }
    }
    
    private var addressIcoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.dropinPrimary)
                .opacity(0.2)
                .frame(width: 45, height: 45)
            Image(systemName: "pin")
                .textStyle(.body, color: .dropinPrimary)
        }
    }
    
    private var addressBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.backgroundPrimary)
            .stroke(.separator)
    }


    @ViewBuilder
    private var addressView: some View {
        if fetching {
            fetchingAddressView
        } else if let address = address {
            fetchedAddressView(address)
        } else {
            fetchedAddressFailedView
        }
    }

    private var fetchedAddressFailedView: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.textPrimary)
                    .opacity(0.2)
                    .frame(width: 45, height: 45)
                Image(systemName: "wifi.slash")
                    .textStyle(.body, color: .textPrimary)
            }
            .padding()
            VStack(spacing: 0) {
                Text("address_picker.fetch_error.title")
                    .textStyle(.bodySemibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("address_picker.fetch_error.body")
                    .textStyle(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
            .padding(.top)
            .padding(.bottom)
            .padding(.trailing)
        }
        .background(addressBackground)
    }

    private func fetchedAddressView(_ address: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            addressIcoView
                .padding()
            VStack(spacing: 0) {
                let lines = address.components(separatedBy: "\n")
                let firstLine = lines.first ?? address
                let rest = lines.dropFirst().joined(separator: "\n")
                
                Text(firstLine)
                    .minimumScaleFactor(0.5)
                    .textStyle(.bodySemibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !rest.isEmpty {
                    Text(rest)
                        .minimumScaleFactor(0.5)
                        .textStyle(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(.top)
            .padding(.bottom)
            .padding(.trailing)
        }
        .contextMenu {
            Button(action: { copyAddressToClipboard() } ){
                Text("common.copy_address")
            }
        }
        .background(addressBackground)
    }
    
    private var fetchingAddressView: some View {
        HStack(alignment: .top, spacing: 0) {
            addressIcoView
                .padding()
            VStack(spacing: 0) {
                Text("address_picker.fetching")
                    .textStyle(.placeholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                    .padding(.trailing)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.backgroundSecondary)
                    .frame(height: 8)
                    .padding(.top, 8)
                    .padding(.trailing, 80)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.backgroundSecondary)
                    .frame(height: 8)
                    .padding(.top, 8)
                    .padding(.trailing, 120)
            }
            .padding(.bottom)
        }
        .background(addressBackground)
    }

    private var coordsView: some View {
        VStack(spacing: 0) {
            Text("common.coordinates")
                .textStyle(.caption, color: .textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("common.coordinates", text: $tfCoords)
                .textStyle(.formSectionTitle2)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 0.5))
                }
                .padding(.top, 5)
                .onSubmit {
                    submitCoords()
                }
            Text("address_picker.coord_desc")
                .textStyle(.caption2, color: .textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
        }
        //.background(Color.red.opacity(0.3))
    }

    private var coordsInfoView: some View {
        HStack(spacing: 0) {
            Image(systemName: "scope")
                .textStyle(.body, color: .textTertiary)
            Text(tfCoords)
                .textStyle(.subheadline, color: .textTertiary)
                .padding(.leading, 10)
            Spacer()
            TextButton(text: "common.edit",
                       action: { editCoords.toggle() })
        }
    }

    // MARK: - private methods
    private func dismiss() {
        isPresented.toggle()
    }
    
    private func submitCoords() {
        guard let tmpCoords = CLLocationCoordinate2D(string: tfCoords) else {
            showInvalidAlert = true
            tfCoords = coords.formatted()
            return
        }
        onCoordsEdit(tmpCoords)
        // the coords update will be made externally in parallell of centering map
        //coords = tmpCoords
    }
    
    private func copyAddressToClipboard() {
        guard let address = address else { return }
        UIPasteboard.general.string = address
    }
}

#Preview {
    @Previewable @State var presented: Bool = false
    @Previewable @State var coords = CLLocationCoordinate2D.barcelona
    //@Previewable @State var address: String? = nil
    @Previewable @State var address: String? = "4 rue jean bart\n17138 L'aubreçay\nFrance"
    @Previewable @State var fetching: Bool = false

    Map(initialPosition: .camera(.init(centerCoordinate: .barcelona, distance: 1000))) { }
    .onAppear {
        presented = true
    }
    .sheetOverlay(isPresented: $presented) {
        AddressPickerView(editCoords: false,
                          coords: $coords,
                          address: $address,
                          fetching: $fetching,
                          isPresented: $presented,
                          onCoordsEdit: { ll in coords = ll },
                          onComplete: {
            Log.debug("complete")
        })
        .sheetOverlayDetents([.height(DropinApp.ui.addressPickerSheetHeight)])
        .sheetOverlayBackground(.surface1)
    }
}
