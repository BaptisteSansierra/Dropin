//
//  PlaceHeaderView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlaceHeaderView: View {
    
    // MARK: - State & Bindings
    @Binding private var place: Place
    @Binding private var showingMarkerList: Bool
    @Binding private var showPhoneField: Bool
    @Binding private var showUrlField: Bool
    @Binding private var showNotesField: Bool

    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - private var
    private var editEnabled: Bool
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                
                ZStack(alignment: .topLeading) {
                    let color = place.group == nil ? .dropinPrimary : Color(rgba: place.group!.colorHex)
                    PlaceAnnotationView(sysImage: place.systemImage,
                                        color: color)
                    .padding()
                    IcoButton(systemImage: "ellipsis", icoSize: 14)
                        .padding(0)
                        .onTapGesture {
                            showingMarkerList.toggle()
                        }
                        .opacity(editEnabled ? 1 : 0)
                }
                VStack(alignment: .leading) {
                    TextField(editEnabled ? "Give place a name" : "N/A", text: $place.name)
                        .font(.title)
                        .autocorrectionDisabled()
                        .disabled(!editEnabled)
                    Text(place.address.isEmpty ? "" : place.address)
                        .font(.callout)
                        .foregroundStyle(.gray)
                        .onTapGesture(count: 2, perform: {
                            navigationContext.showingAddressToClipboard.toggle()
                            print("COPY TO CLIPBOARD: \(place.address)")
                            UIPasteboard.general.string = place.address
                        })
//                        .onLongPressGesture {
//                            navigationContext.showingAddressToClipboard.toggle()
//                            print("COPY TO CLIPBOARD: \(place.address)")
//                            UIPasteboard.general.string = place.address
////                            UIPasteboard.general.setValue(place.address, forPasteboardType: UTType.plainText.identifier)
//                        }
                }
            }
            .padding(EdgeInsets(top: 15,
                                leading: 15,
                                bottom: !showPhoneField || !showUrlField || !showNotesField ? 0 : 15,
                                trailing: 15))
            
            if editEnabled {
                headerOptionalsView
                    .padding(0)
            }
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    // MARK: - Subviews
    private var headerOptionalsView: some View {
        HStack {
            if !showPhoneField {
                IcoButton(systemImage: "phone", icoSize: 14)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        withAnimation {
                            showPhoneField.toggle()
                        }
                    }
            }
            if !showUrlField {
                IcoButton(systemImage: "link", icoSize: 14)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        withAnimation {
                            showUrlField.toggle()
                        }
                    }
            }
            if !showNotesField {
                IcoButton(systemImage: "note.text", icoSize: 14)
                    .padding(.horizontal, 15)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        withAnimation {
                            showNotesField.toggle()
                            //scrollPosition.scrollTo(edge: .bottom)
                            // TODO: add a onChange in upperView to scoll to notes
                        }
                    }
            }
        }
    }
    
    // MARK: - init
//    init(place: Binding<Place>,
//         showingMarkerList: Binding<Bool>,
//         showPhoneField: Binding<Bool>,
//         showUrlField: Binding<Bool>,
//         showNotesField: Binding<Bool>) {
//        self._place = place
//        self._showingMarkerList = showingMarkerList
//        self._showPhoneField = showPhoneField
//        self._showUrlField = showUrlField
//        self._showNotesField = showNotesField
//        self._edit = true
//    }
    
    init(place: Binding<Place>,
         showingMarkerList: Binding<Bool>,
         showPhoneField: Binding<Bool>,
         showUrlField: Binding<Bool>,
         showNotesField: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingMarkerList = showingMarkerList
        self._showPhoneField = showPhoneField
        self._showUrlField = showUrlField
        self._showNotesField = showNotesField
        self.editEnabled = editEnabled
    }
}

