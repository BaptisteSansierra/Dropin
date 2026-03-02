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

    // MARK: - init
    init(viewModel: PlaceDetailsSheetViewModel,
         place: Binding<PlaceUI>) {
        self.viewModel = viewModel
        self._place = place
    }
    
    // MARK: - Body
    var body: some View {

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
                    .foregroundStyle(.backgroundPrimary)
                    .frame(height: 60)
                    .shadow(color: .textPrimary.opacity(0.2), radius: 3, x: 0, y: -5)
                footer
            }
        }
        .confirmationDialog("navigate",
                            isPresented: $showingNavigationDialog,
                            actions: {
            Button("navigate_link_google") {
                //routeThrowGoogle()
            }
            Button("navigate_link_apple") {
                //routeThrowApple()
            }
            Button("navigate_link_waze") {
                //routeThrowWaze()
            }
        })
    }
    
    private var footer: some View {
        HStack(alignment: .center, spacing: 15) {
            // Go button
            MainButton(text: "common.go", maxWidth: nil, action: onPressGo)
                .padding(.leading, 15)
            // Edit button
            MainButton(text: "common.edit", maxWidth: nil, action: onPressEdit)
                .padding(.trailing, 15)
        }
    }

    // MARK: - Actions
    private func onPressGo() {
        showingNavigationDialog.toggle()
    }
    
    private func onPressEdit() {
        dismiss()
        viewModel.pushPlaceDetailsView(placeId: place.id)
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
    }
}

#endif
