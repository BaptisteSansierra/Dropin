//
//  ProfileView.swift
//  Dropin
//
//  Presented modally (its own NavigationStack) from RootView via the side-menu
//  header — not pushed onto RootView's stack, since nesting a NavigationStack
//  inside another's content causes toolbar/nav-bar cross-talk in SwiftUI.
//  EditDisplayNameView/DeleteAccountView are pushed within *this* stack via
//  ProfileCoordinator.
//

import SwiftUI

struct ProfileView: View {

    @State private var viewModel: ProfileViewModel
    @State private var confirmLogout: Bool = false
    @State private var showSyncInfo: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    CloseButton {
                        dismiss()
                    }
                    .padding(.trailing, 20)
                }
                //ScrollView {
                    VStack(spacing: 0) {
                        identityBlock
                            .padding(.top, 26)

                        accountCard
                            .padding(.top, 28)
                            .padding(.horizontal, 20)

                        Spacer(minLength: 60)

                        logoutRow
                            .padding(.horizontal, 20)

                        deleteAccountRow
                            .padding(.top, 14)
                            //.padding(.bottom, 40)
                    }
                }
            //}
            .frame(maxHeight: .infinity)
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: ProfileNavigationItem.self) { item in
                resolveDestination(item)
            }
        }
        // First confirmation: are you sure you want to log out?
        .confirmationDialog("profile.logout.confirm_title",
                            isPresented: $confirmLogout,
                            titleVisibility: .visible) {
            Button("profile.logout.confirm", role: .destructive) {
                Task { await viewModel.signOut { } }
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
                Task { await viewModel.forceSignOut { } }
            }
            Button("profile.logout.more_info") {
                // Dismiss this alert, then defer the info alert so SwiftUI
                // doesn't hit "presentation in progress" trying to chain.
                viewModel.pendingForceSignOut = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    showSyncInfo = true
                }
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
        // Tertiary info: explains WHY there are unsynced changes and what to do.
        .alert("profile.logout.info_title",
               isPresented: $showSyncInfo) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text("profile.logout.info_body")
        }
    }

    @ViewBuilder
    private func resolveDestination(_ item: ProfileNavigationItem) -> some View {
        switch item {
            case .editName:
                viewModel.createEditDisplayNameView()
            case .accountDeletion:
                viewModel.createDeleteAccountView()
        }
    }

    // MARK: - Subviews
    private var identityBlock: some View {
        VStack(spacing: 10) {
            ProfileBadgeView(initials: viewModel.avatarInitial,
                             style: .large,
                             bgColor: .dropinPrimary,
                             fgColor: .backgroundPrimary)

            Text(viewModel.displayName.isEmpty ? String(localized: "common.na") : viewModel.displayName)
                .textStyle(.profileName)

            Text(verbatim: planLabel)
                .textStyle(.bodySemibold, color: .dropinPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.dropinPrimary.opacity(0.14), in: Capsule())
        }
    }

    private var accountCard: some View {
        VStack(spacing: 0) {
            accountRow(label: "profile.display_name",
                       value: viewModel.displayName,
                       showChevron: true) {
                viewModel.pushEditDisplayName()
            }

            Rectangle()
                .fill(.fieldBorder)
                .frame(height: 1)
                .padding(.leading, 16)

            accountRow(label: "profile.email",
                       value: viewModel.email ?? "—",
                       showChevron: false,
                       action: nil)
        }
        .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.fieldBorder, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func accountRow(label: LocalizedStringKey,
                            value: String,
                            showChevron: Bool,
                            action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(label)
                    .textStyle(.body)
                Spacer()
                Text(value)
                    .textStyle(.body, color: .textSecondary)
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var logoutRow: some View {
        SecondaryButton(text: "profile.logout") {
            confirmLogout = true
        }
        .disabled(viewModel.isSigningOut)
    }

    private var deleteAccountRow: some View {
        TextButton(text: "profile.delete_account",
                   postSystemImage: "chevron.right",
                   postSystemImageFont: .system(size: 12,
                                                weight: .semibold),
                   foreground: .destructive) {
            viewModel.pushAccountDeletion()
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
