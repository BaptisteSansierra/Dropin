//
//  MapstrImportConfigView.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import SwiftUI

struct MapstrImportConfigView: View {

    @State private var viewModel: MapstrImportConfigViewModel
    let onConfirm: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCategoryNameFocused: Bool

    init(viewModel: MapstrImportConfigViewModel, onConfirm: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onConfirm = onConfirm
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TextField("settings.mapstr_import.category_placeholder", text: $viewModel.groupName)
                        .autocorrectionDisabled()
                        .focused($isCategoryNameFocused)
                } header: {
                    Text("settings.mapstr_import.category_section")
                } footer: {
                    Text("settings.mapstr_import.category_footer")
                }
            }
            .navigationTitle("settings.mapstr_import.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.next") {
                        Task { await viewModel.nextTapped() }
                    }
                    .disabled(viewModel.isConfirmDisabled)
                }
            }
            .task {
                await viewModel.resolveInitialName()
            }
            .onChange(of: isCategoryNameFocused) { wasFocused, isFocused in
                guard wasFocused, !isFocused else { return }
                Task { await viewModel.handleKeyboardDismiss() }
            }
            .onChange(of: viewModel.confirmedCategoryName) { _, newValue in
                guard let newValue else { return }
                dismiss()
                onConfirm(newValue)
            }
            .alert("settings.mapstr_import.name_updated_title",
                   isPresented: $viewModel.showingNameUpdatedAlert) {
                Button("common.ok", role: .cancel) { }
            } message: {
                Text("settings.mapstr_import.name_updated_body")
            }
        }
    }
}

#if DEBUG
#Preview {
    MapstrImportConfigView(
        viewModel: MockContainer().appContainer.createMapstrImportConfigViewModel(baseName: "Mapstr"),
        onConfirm: { _ in }
    )
}
#endif
