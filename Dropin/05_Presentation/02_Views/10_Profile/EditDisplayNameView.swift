//
//  EditDisplayNameView.swift
//  Dropin
//
//  Pushed from Profile's display-name row via the MainCoordinator.
//

import SwiftUI

struct EditDisplayNameView: View {

    @State private var viewModel: EditDisplayNameViewModel
    @FocusState private var isFocused: Bool

    init(viewModel: EditDisplayNameViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 9) {
                Text("edit_display_name.section_title")
                    .textStyle(.formSectionTitle2)
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    TextField("profile.display_name", text: $viewModel.name)
                        .textStyle(.stringFieldContent)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            guard viewModel.canSave else { return }
                            Task { await viewModel.save() }
                        }

                    if !viewModel.name.isEmpty {
                        Button {
                            viewModel.clear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.fieldBorder, lineWidth: 1)
                }

                Text("edit_display_name.helper")
                    .textStyle(.caption, color: .textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isFocused = true
        }
        .navigationTitle("common.profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.save") {
                    Task { await viewModel.save() }
                }
                .textStyle(.bodySemibold, color: viewModel.canSave ? .dropinPrimary : .textTertiary)
                .disabled(!viewModel.canSave)
            }
        }
    }
}

#if DEBUG
struct MockEditDisplayNameView: View {
    var mock: MockContainer
    var body: some View {
        VStack {
            if ready {
                mock.appContainer.createEditDisplayNameView()
            } else {
                ProgressView()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            ready = true
        }
    }
    @State private var ready = false
    init() {
        self.mock = MockContainer()
        mock.loadProfile()
    }
}

#Preview {
    NavigationStack {
        MockEditDisplayNameView()
    }
}
#endif
