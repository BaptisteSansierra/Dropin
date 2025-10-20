//
//  PlaceDetailsSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/8/25.
//

import SwiftUI

struct PlaceDetailsSheetView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: PlaceDetailsSheetViewModel
    @Binding private var place: PlaceUI
    @State private var editMode: PlaceEditMode = .none
    @State private var showingNavigationDialog: Bool = false

    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - Body
    var body: some View {
        @Bindable var navigationContext = navigationContext

        VStack(alignment: .center, spacing: 0) {
            viewModel.createPlaceDetailsContentView(place: $place, editMode: $editMode)
            //PlaceDetailsContentView(place: $place, editMode: $editMode)
                .navigationTitle(place.name)
                .navigationBarTitleDisplayMode(.inline)
            
//                .toolbar {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button(editMode == .edit ? "common.cancel" : "common.edit") {
//                            switch editMode {
//                                case .edit:
//                                    editMode = .cancel
//                                case .none:
//                                    editMode = .edit
//                                default:
//                                    ()
//                            }
//                        }
//                        .tint(.dropinPrimary)
//                    }
//                }
            
            // Footer
            ZStack(alignment: .center) {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(height: 60)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: -5)
                footer
            }
        }
        .confirmationDialog("navigate",
                            isPresented: $showingNavigationDialog,
                            actions: {
            Button("navigate_link_google") {
                routeThrowGoogle()
            }
            Button("navigate_link_apple") {
                routeThrowApple()
            }
            Button("navigate_link_waze") {
                routeThrowWaze()
            }
        })
        .alert("alert.address_copied_title",
               isPresented: $navigationContext.showingAddressToClipboard,
               actions: {
            Button("common.ok", role: .cancel) { }
        },
               message: {
            Text("alert.address_copied_body")
        })
    }
    
    private var footer: some View {
        HStack(alignment: .center, spacing: 15) {
            // Go button
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .foregroundStyle(.dropinPrimary)
                    .frame(height: DropinApp.ui.button.height)
                Text("common.go")
                    .foregroundStyle(.white)
            }
            .padding(.leading, 15)
            .onTapGesture { onPressGo() }
            // Edit button
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .foregroundStyle(.dropinPrimary)
                    .frame(height: DropinApp.ui.button.height)
                Text("common.edit")
                    .foregroundStyle(.white)
            }
            .padding(.trailing, 15)
            .onTapGesture { onPressEdit() }
        }
    }

    // MARK: - init
    init(viewModel: PlaceDetailsSheetViewModel, place: Binding<PlaceUI>) {
        self.viewModel = viewModel
        self._place = place
    }
    
    // MARK: - Actions
    private func onPressGo() {
        showingNavigationDialog.toggle()
    }
    
    private func onPressEdit() {
        dismiss()
        navigationContext.navigationPath.append(PlaceMapper.toDomain(place))
    }
    
    private func routeThrowGoogle() {
        //guard let url = URL(string: "comgooglemaps://?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"comgooglemaps://?daddr=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }

    private func routeThrowApple() {
        //guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.coordinates.latitude),\(place.coordinates.longitude)") else { return }
        guard let url = URL(string:"http://maps.apple.com/?daddr=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }

    private func routeThrowWaze() {
        guard let url = URL(string: "https://www.waze.com/ul?ll=\(place.coordinates.latitude)-\(place.coordinates.longitude)&navigate=yes") else { return }
        //guard let url = URL(string:"https://www.waze.com/ul?ll=\(place.address)") else { return }
        UIApplication.shared.open(url)
    }
}

#if DEBUG
struct MockPlaceDetailsSheetView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createPlaceDetailsSheetView(place: $place)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
    }
}

#Preview {
    NavigationStack {
        MockPlaceDetailsSheetView()
            .environment(NavigationContext())
    }
}

#endif
