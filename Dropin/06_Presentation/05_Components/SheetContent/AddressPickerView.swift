//
//  AddressPickerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/3/26.
//

import SwiftUI
import CoreLocation

struct AddressPickerView: View {
        
    @Binding private var coords: CLLocationCoordinate2D
    @Binding private var address: String?
    
    let onFetchAddress: () -> Void
    let onComplete: () -> Void

    init(coords: Binding<CLLocationCoordinate2D>,
         address: Binding<String?>,
         onFetchAddress: @escaping () -> Void,
         onComplete: @escaping () -> Void) {
        self._coords = coords
        self._address = address
        self.onFetchAddress = onFetchAddress
        self.onComplete = onComplete
    }
    
    var body: some View {
        //VStack {
            VStack(spacing: 0) {
                
                /*
                 HStack(alignment: .center) {
                 Text("common.coordinates")
                 .textStyle(.formSectionTitle)
                 Text(verbatim: coords.formatted())
                 .textStyle(.formSectionTitle2)
                 .padding(.leading, 20)
                 Spacer()
                 }
                 .padding(.leading)
                 .padding(.top, 20)
                 */
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
                        //.shadow(radius: 5)
                    }
                    .padding(.horizontal)
                
                Text(verbatim: CLLocationCoordinate2D.barcelona.formatted())
                    .textStyle(.formSectionTitle2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red)
                            .stroke(.gray, style: StrokeStyle(lineWidth: 0.5))
                        //.shadow(radius: 5)
                    }
                    .padding(.horizontal)

                
                VStack(spacing: 0) {
                    Text("common.address")
                        .textStyle(.formSectionTitle)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 5)
                    //let address = viewModel.pickedAddress == nil ? String(localized: "common.na") : viewModel.pickedAddress!
                    let address = self.address == nil ? String(localized: "common.na") : self.address!
                    Text(address)
                        .textStyle(.formSectionTitle2)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    //.padding(.top, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                                .stroke(.gray, style: StrokeStyle(lineWidth: 0.5))
                            //.shadow(radius: 5)
                        }
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                //                   .padding(.horizontal)
                
                
                
                /*
                 VStack(spacing: 0) {
                 Text("common.address")
                 .textStyle(.formSectionTitle)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 let address = viewModel.pickedAddress == nil ? "common.na" : viewModel.pickedAddress!
                 Text(address)
                 .textStyle(.formSectionTitle2)
                 .lineLimit(nil)
                 .fixedSize(horizontal: false, vertical: true)
                 .padding(.top, 5)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 }
                 .padding(.top, 20)
                 .padding(.leading)
                 */
                
                
                Spacer()
                SecondaryButton(text: "create_place.fetch") {
                    onFetchAddress()
                }
                .padding(.bottom)
                MainButton(text: "create_place.create") {
                    onComplete()
                }
                .padding(.bottom, 40)
            }
        //}
    }
}

#Preview {
    
    @Previewable @State var coords = CLLocationCoordinate2D.barcelona
    @Previewable @State var address: String? = "..."

    AddressPickerView(coords: $coords,
                      address: $address) {
        print("fetch")
    } onComplete: {
        print("complete")
    }
}
