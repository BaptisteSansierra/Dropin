//
//  PlaceHeaderView.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/9/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlaceHeaderView: View {
    
    // MARK: - State & Bindings
    /// show/hide the copied to clipboard alert
    @State private var showingAddressToClipboard: Bool = false
    @Binding private var place: PlaceUI
    //@Binding private var showingMarkerList: Bool
    @Environment(AppSettings.self) private var appSettings

    // MARK: - private properties
    //private var editEnabled: Bool
    private var isNameFocused: FocusState<Bool>.Binding

    // MARK: - init
    init(place: Binding<PlaceUI>,
         //showingMarkerList: Binding<Bool>,
         //editEnabled: Bool,
         isNameFocused: FocusState<Bool>.Binding) {
        self._place = place
        //self._showingMarkerList = showingMarkerList
        //self.editEnabled = editEnabled
        self.isNameFocused = isNameFocused
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                switch appSettings.mapSettings.pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(color: place.groupColor,
                                            icon: place.group?.icon,
                                            iconExtra: place.icon)
                        .padding(.trailing)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.group?.icon,
                                               iconExtra: place.icon,
                                               size: 40,
                                               shadow: false)
                        .padding(.trailing)
                }
                VStack(alignment: .leading) {
                    TextField("placeholder.place_name", text: $place.name)
                        .textStyle(.body)
                        .autocorrectionDisabled()
                        .focused(isNameFocused)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.backgroundPrimary)
                                .stroke(.separator)
                        }
                    Text(place.address.flatMap { $0.isEmpty ? nil : $0 } ?? place.coordinates.formatted())
                        .textStyle(.stringFieldTitle)
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
//            .padding(EdgeInsets(top: 15,
//                                leading: 15,
//                                bottom: 0,
//                                trailing: 15))
        }
        .alertOk(isPresented: $showingAddressToClipboard,
                 title: "alert.address_copied_title",
                 body: "alert.address_copied_body")
    }
    
    // MARK: private methods
    private func copyAddressToClipboard() {
        guard let address = place.address else { return }
        showingAddressToClipboard.toggle()
        UIPasteboard.general.string = address
    }
}

#if DEBUG
struct MockPlaceHeaderView: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var placeNoAddress: PlaceUI
    @FocusState var isNameFocused

    var body: some View {
        VStack {
            PlaceHeaderView(place: $place,
                            isNameFocused: $isNameFocused)
            .padding(.bottom, 30)
            Divider()
            PlaceHeaderView(place: $placeNoAddress,
                            isNameFocused: $isNameFocused)
            .padding(.top, 30)
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
        self.placeNoAddress = mock.getNoAddressPlaceUI()
    }
}

#Preview {
    MockPlaceHeaderView()
        .environment(AppSettings())
}

#endif
