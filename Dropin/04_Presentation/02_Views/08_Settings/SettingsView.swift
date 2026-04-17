//
//  SettingsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: SettingsViewModel
    @State private var tags: [TagUI] = [TagUI]()
    @State private var showingRemoveAlert: Bool = false
    @State private var tagToRemove: TagUI? = nil
    @Binding private var showingSideMenu: Bool
    
    // MARK: - init
    init(viewModel: SettingsViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            VStack {
                Button {
                    Task {
                        do {
                            try await viewModel.export()
                        } catch {
                            // TODO: handle error
                        }
                    }
                } label: {
                    Label("common.export", systemImage: "square.and.arrow.up")
                }
            }
            .navigationTitle("common.settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
        }
    }
}
