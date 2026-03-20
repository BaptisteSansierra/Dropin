//
//  PlaceHeaderViewV2.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlaceHeaderViewV2: View {
    
    // MARK: - State & Bindings
    /// show/hide the copied to clipboard alert
    @State private var showingAddressToClipboard: Bool = false
    @Binding private var place: PlaceUI
    @Binding private var showingMarkerList: Bool
    private var isNameFocused: FocusState<Bool>.Binding
    
    // MARK: - private var
    private var editEnabled: Bool
    
    // MARK: - init
    init(place: Binding<PlaceUI>,
         showingMarkerList: Binding<Bool>,
         editEnabled: Bool,
         isNameFocused: FocusState<Bool>.Binding) {
        self._place = place
        self._showingMarkerList = showingMarkerList
        self.editEnabled = editEnabled
        self.isNameFocused = isNameFocused
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                
                ZStack(alignment: .topLeading) {
                    switch AnnotationViewFactory.pinMode {
                        case .rect:
                            PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon)
                            .padding()
                            IcoButton(systemImage: "ellipsis",
                                      icoSize: 14,
                                      action: { showingMarkerList.toggle() })
                                .padding(0)
                                .opacity(editEnabled ? 1 : 0)
                        case .pin:
                            PlacePinAnnotationView(color: place.groupColor,
                                                   icon: place.group?.icon,
                                                   iconExtra: place.icon,
                                                   size: 40)
                            .padding()
                            IcoButton(systemImage: "ellipsis",
                                      icoSize: 14,
                                      action: { showingMarkerList.toggle() })
                                .padding(0)
                                .opacity(editEnabled ? 1 : 0)
                                .offset(x: 3, y: 3)
                    }
                }
                VStack(alignment: .leading) {
                    TextField(editEnabled ? "placeholder.place_name" : "common.na", text: $place.name)
                        .textStyle(.title)
                        .autocorrectionDisabled()
                        .disabled(!editEnabled)
                        .focused(isNameFocused)
                    Text(place.address.isEmpty ? "" : place.address)
                        .textStyle(.placeholder)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                                bottom: 0,
                                trailing: 15))
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

    // MARK: private methods
    private func copyAddressToClipboard() {
        showingAddressToClipboard.toggle()
        UIPasteboard.general.string = place.address
    }
}

#if DEBUG
struct MockPlaceHeaderViewV2: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var showingMarkerList: Bool = true
    @FocusState var isNameFocused

    var body: some View {
        PlaceHeaderViewV2(place: $place,
                          showingMarkerList: $showingMarkerList,
                          editEnabled: true,
                          isNameFocused: $isNameFocused)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
    }
}

#Preview {
    NavigationStack {
        MockPlaceHeaderViewV2()
    }
}

#endif
