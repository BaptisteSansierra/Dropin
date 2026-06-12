//
//  ProfileView.swift
//  Dropin
//
//  Hosted as a sheet from RootView when the side-menu header is tapped.
//

import SwiftUI

struct ProfileView: View {

    @State private var viewModel: ProfileViewModel
    @State private var confirmLogout: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            
            ScrollView {
                
                //ZStack {
                    
//                    VStack(spacing: 0) {
//                        Divider()
////                        Color.backgroundSecondary
////                            .ignoresSafeArea()
////                            .padding(.top, 0)
//                    }
                    
                    VStack(spacing: 0) {
                        avatarBlock
                        //Divider()
                        //    .padding(.top, 24)
                        
                        //VStack(spacing: 0) {
                        displayNameField
                            .padding(.top, 24)
                            .padding(.horizontal)
                        planRow
                            .padding(.top, 24)
                            .padding(.horizontal)
                        emailRow
                            .padding(.top, 20)
                            .padding(.horizontal)
                        Spacer().frame(height: 24)
                        logoutButton
                            .padding(.top, 40)
                        //}
                        //.frame(maxWidth: .infinity, maxHeight: .infinity)
                        //.background(.backgroundSecondary)
                    }
                    .padding(.horizontal, 0)
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                //}
                
                
            }
            //.background(.backgroundPrimary)
            .navigationTitle("common.profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") {
                        Task { await viewModel.saveNow(); dismiss() }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
        .onDisappear { viewModel.discardInvalidDraftOnDismiss() }
        // First confirmation: are you sure you want to log out?
        .confirmationDialog("profile.logout.confirm_title",
                            isPresented: $confirmLogout,
                            titleVisibility: .visible) {
            Button("profile.logout.confirm", role: .destructive) {
                Task { await viewModel.signOut() }
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text("profile.logout.confirm_body")
        }
        // Second confirmation: only fires if the first sign-out attempt threw
        // because of unsynced offline data or a sync that didn't fully clear.
        .alert(forceSignOutTitle,
               isPresented: forceSignOutBinding,
               presenting: viewModel.pendingForceSignOut) { _ in
            Button("profile.logout.force", role: .destructive) {
                Task { await viewModel.forceSignOut() }
            }
            Button("common.cancel", role: .cancel) {
                viewModel.pendingForceSignOut = nil
            }
        } message: { reason in
            switch reason {
                case .offline(let count):
                    Text("profile.logout.offline_body_\(count)")
                case .syncFailed(let count):
                    Text("profile.logout.sync_failed_body_\(count)")
            }
        }
    }

    // MARK: - Subviews
    private var avatarBlock: some View {
        VStack(spacing: 8) {
            ProfileBadgeView(initials: viewModel.avatarInitial,
                             style: .large,
                             bgColor: .dropinPrimary,
                             fgColor: .backgroundPrimary)
        }
    }

    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.display_name")
                .textStyle(.formSectionTitle2)

            TextField("profile.display_name", text: $viewModel.draft)
                .textStyle(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.backgroundPrimary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.isValid ? .backgroundTertiary : .red, lineWidth: 1)
                )
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: viewModel.draft) { _, _ in viewModel.scheduleSave() }
                .onSubmit { Task { await viewModel.saveNow() } }

            if let error = viewModel.validationError {
                Text(error)
                    .textStyle(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var planRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.plan")
                .textStyle(.formSectionTitle2)
            HStack {
                Text(verbatim: planLabel)
                    .textStyle(.bodySemibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.dropinPrimary.opacity(0.15),
                                in: Capsule())
                    .foregroundStyle(.dropinPrimary)
                Spacer()
            }
        }
    }

    private var emailRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.email")
                .textStyle(.formSectionTitle2)
            HStack {
                Text(viewModel.email ?? "—")
                    .textStyle(.body)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private var logoutButton: some View {
        VStack {
            DestructiveButton(text: "profile.logout") {
                confirmLogout = true
            }
            .disabled(viewModel.isSigningOut)

            /*
            Button(role: .destructive) {
                confirmLogout = true
            } label: {
                HStack {
                    if viewModel.isSigningOut {
                        ProgressView()
                    }
                    Text("profile.logout")
                        .textStyle(.mainButton)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DropinApp.ui.button.height)
                .background(.destructive, in: Capsule())
                .foregroundStyle(.white)
            }
            .disabled(viewModel.isSigningOut)
             */
        }
    }

    // MARK: - Helpers

    private var planLabel: String {
        switch viewModel.plan {
            case .admin:      return "Admin"
            case .invited:    return "Invited"
            case .earlyStage: return "Early Stage"
            case .free, .none: return "Free"
            case .paid:       return "Paid"
        }
    }

    private var forceSignOutTitle: LocalizedStringKey {
        switch viewModel.pendingForceSignOut {
            case .offline:     return "profile.logout.offline_title"
            case .syncFailed:  return "profile.logout.sync_failed_title"
            case .none:        return ""
        }
    }

    private var forceSignOutBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingForceSignOut != nil },
            set: { if !$0 { viewModel.pendingForceSignOut = nil } }
        )
    }
}

#if DEBUG
struct MockProfileView: View {
    var mock: MockContainer
    var body: some View {
        VStack {
            if ready {
                mock.appContainer.createProfileView()
            } else {
                ProgressView()
            }
        }
        .task {
            // wait the mock profiloe to be loaded before displaying
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
    MockProfileView()
}
#endif
