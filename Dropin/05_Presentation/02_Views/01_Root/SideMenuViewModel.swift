//
//  SideMenuViewModel.swift
//  Dropin
//

import SwiftUI

@MainActor
@Observable class SideMenuViewModel {

    /// Binding to the parent's `showingProfile` flag. The header's tap
    /// handler writes through this; RootView owns the source of truth and
    /// attaches the actual `.fullScreenCover(isPresented:)` modifier.
    @ObservationIgnored var showingProfile: Binding<Bool>

    @ObservationIgnored private let profileService: any ProfileServiceProtocol

    init(profileService: any ProfileServiceProtocol,
         showingProfile: Binding<Bool>) {
        self.profileService = profileService
        self.showingProfile = showingProfile
    }

    var profile: ProfileEntity? { profileService.profile }
    var displayName: String? { profile?.displayName }
    var email: String? { profile?.email }

    var headerTitle: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return "Undefined Name"
    }

    var headerSubtitle: String {
        if let email, !email.isEmpty { return email }
        return "Undefined email"
    }

    var avatarInitial: String {
        let placeholder = "N/A"
        guard let displayName = displayName else { return placeholder }
        let source = displayName.isEmpty ? placeholder : displayName.initials()
        return source.uppercased()
    }

    func openProfile() {
        showingProfile.wrappedValue = true
    }
}
