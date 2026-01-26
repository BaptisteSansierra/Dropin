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
    /// show/hide the copied to clipboard alert
    @State private var showingAddressToClipboard: Bool = false
    @Binding private var place: PlaceUI
    @Binding private var showingMarkerList: Bool
    @Binding private var showPhoneField: Bool
    @Binding private var showUrlField: Bool
    @Binding private var showNotesField: Bool

    // MARK: - private var
    private var editEnabled: Bool
    
    // MARK: - init
    init(place: Binding<PlaceUI>,
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
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                
                ZStack(alignment: .topLeading) {
                    let color = place.groupColor
                    PlaceAnnotationView(color: color,
                                        icon: place.group?.icon,
                                        iconExtra: place.icon)
                    .padding()
                    IcoButton(systemImage: "ellipsis", icoSize: 14)
                        .padding(0)
                        .onTapGesture {
                            showingMarkerList.toggle()
                        }
                        .opacity(editEnabled ? 1 : 0)
                }
                VStack(alignment: .leading) {
                    TextField(editEnabled ? "placeholder.place_name" : "common.na", text: $place.name)
                        .textStyle(.title)
                        .autocorrectionDisabled()
                        .disabled(!editEnabled)
                    Text(place.address.isEmpty ? "" : place.address)
                        .textStyle(.placeholder)
                        .onLongPressGesture {
                            copyAddressToClipboard()
                        }
                        .onTapGesture(count: 2, perform: {
                            copyAddressToClipboard()
                        })
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
        .alert("alert.address_copied_title",
               isPresented: $showingAddressToClipboard,
               actions: {
            Button("common.ok", role: .cancel) { }
        },
               message: {
            Text("alert.address_copied_body")
        })
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
    
    // MARK: private methods
    private func copyAddressToClipboard() {
        showingAddressToClipboard.toggle()
        print("COPY TO CLIPBOARD: \(place.address)")
        UIPasteboard.general.string = place.address
    }
}

#if DEBUG
struct MockPlaceHeaderView: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var showingMarkerList: Bool = true
    @State var showPhoneField: Bool = false
    @State var showUrlField: Bool = false
    @State var showNotesField: Bool = true

    var body: some View {
        PlaceHeaderView(place: $place,
                        showingMarkerList: $showingMarkerList,
                        showPhoneField: $showPhoneField,
                        showUrlField: $showUrlField,
                        showNotesField: $showNotesField,
                        editEnabled: true)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
    }
}

#Preview {
    NavigationStack {
        MockPlaceHeaderView()
    }
}

#endif
