//
//  DeleteAccountView.swift
//  Dropin
//
//  Pushed from Profile's destructive row via the MainCoordinator.
//

import SwiftUI

struct DeleteAccountView: View {

    @State private var viewModel: DeleteAccountViewModel
    @FocusState private var isGateFocused: Bool

    init(viewModel: DeleteAccountViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    warningBlock
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    consequencesCard
                        .padding(.top, 18)
                        .padding(.horizontal, 24)

                    Text("delete_account.footer_note")
                        .textStyle(.caption, color: .textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 14)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }

            actionButtons
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("profile.delete_account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadCounts()
        }
        .sheet(isPresented: $viewModel.showConfirmationSheet) {
            confirmationSheet
                .presentationDetents([.medium])
                .presentationBackground(.backgroundPrimary)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $viewModel.exportedTemporaryFile) { file in
            ShareSheet(url: file.url) { _ in
                viewModel.exportSheetDismissed()
            }
        }
    }

    // MARK: - subviews
    private var warningBlock: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(.destructive.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "trash")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(.destructive)
                }
                .padding(.bottom, 4)

            Text("delete_account.eyebrow")
                .textCase(.uppercase)
                .textStyle(.caption, color: .textSecondary)

            (Text("delete_account.body_emphasis").font(.bodySemibold).tracking(0.6)
             + Text(" ")
             + Text("delete_account.body_details").font(.bodyRegular).tracking(0.6))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    private var visibleConsequenceRows: [(icon: String, label: LocalizedStringKey, count: Int)] {
        var rows: [(String, LocalizedStringKey, Int)] = []
        if viewModel.counts.places > 0 {
            rows.append(("mappin.and.ellipse", "delete_account.consequence.places", viewModel.counts.places))
        }
        if viewModel.counts.groupsAndTags > 0 {
            rows.append(("folder", "delete_account.consequence.groups_tags", viewModel.counts.groupsAndTags))
        }
        if viewModel.counts.photos > 0 {
            rows.append(("photo", "delete_account.consequence.photos", viewModel.counts.photos))
        }
        return rows
    }

    private var consequencesCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleConsequenceRows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Rectangle()
                        .fill(.fieldBorder)
                        .frame(height: 1)
                        .padding(.leading, 16)
                }
                HStack(spacing: 12) {
                    Image(systemName: row.icon)
                        .foregroundStyle(.textSecondary)
                    Text(row.label)
                        .textStyle(.body)
                    Spacer()
                    Text(verbatim: "\(row.count)")
                        .textStyle(.body, color: .textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.fieldBorder, lineWidth: 1)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            
            SecondaryButton(text: "delete_account.export_button",
                            systemImage: "square.and.arrow.up",
                            progress: viewModel.isExporting ? .run(color: .dropinPrimary, replaceContent: false) : .none) {
                Task { await viewModel.export() }
            }
            .disabled(viewModel.isExporting)

            DestructiveButton(text: "profile.delete_account") {
                viewModel.agreementText = ""
                viewModel.deleteError = nil
                viewModel.showConfirmationSheet = true
            }
            
            TextButton(text: "common.cancel") {
                viewModel.pop()
            }
        }
    }

    // MARK: - confirmation sheet

    private var confirmationSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
//            Capsule()
//                .fill(.fieldBorder)
//                .frame(width: 38, height: 5)
//                .frame(maxWidth: .infinity)
//                .padding(.top, 8)

            Text("delete_account.gate.title_\(viewModel.confirmToken)")
                .textStyle(.title2)
                .fixedSize(horizontal: false, vertical: true)

            Text("delete_account.gate.body")
                .textStyle(.body, color: .textSecondary)

            HStack {
                TextField(viewModel.confirmToken, text: $viewModel.agreementText)
                    .textStyle(.stringFieldContent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isGateFocused)
                if viewModel.isAgreementValid {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.success)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(viewModel.isAgreementValid ? Color.success : Color.destructive, lineWidth: 1.5)
            }

            if let error = viewModel.deleteError {
                Text(error)
                    .textStyle(.formFieldError)
            }

            deleteConfirmButton

            Button {
                viewModel.showConfirmationSheet = false
            } label: {
                Text("common.cancel")
                    .textStyle(.bodySemibold, color: .dropinPrimary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.backgroundPrimary)
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isGateFocused = true
        }
    }

    private var deleteConfirmButton: some View {
        VStack {
            DestructiveButton(text: "delete_account.gate.confirm_button",
                              progress: viewModel.isDeleting ? .run(color: .backgroundPrimary, replaceContent: true) : .none ) {
                Task { await viewModel.confirmDelete() }
            }
            .disabled(!viewModel.isAgreementValid || viewModel.isDeleting)
            .opacity(viewModel.isAgreementValid ? 1 : 0.5)
        }
    }
}

#if DEBUG
struct MockDeleteAccountView: View {
    var mock: MockContainer
    var body: some View {
        VStack {
            if ready {
                mock.appContainer.createDeleteAccountView()
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
        MockDeleteAccountView()
    }
}
#endif
