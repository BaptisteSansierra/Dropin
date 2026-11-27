//
//  AuthLink.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/11/26.
//

import Foundation

/// Link from a Supabase auth email (sign up confirmation, password reset), opened in the app as a Universal Link instead of its web page
/// `DropinApp.urls`
struct AuthLink: Equatable {

    enum Kind: Equatable {
        /// Verifying it confirms the email and signs the user in
        case emailConfirmation
        /// Verifying it opens a recovery session, only used to choose a new password
        case passwordRecovery
    }

    let kind: Kind
    /// nil when the link carries no token (Supabase error redirect): it can't be used anymore
    let tokenHash: String?

    /// nil for any other URL
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if Self.isPage(DropinApp.urls.emailConfirmedURL, components) {
            kind = .emailConfirmation
        } else if Self.isPage(DropinApp.urls.resetPasswordURL, components) {
            kind = .passwordRecovery
        } else {
            return nil
        }
        tokenHash = components.queryItems?.first { $0.name == "token_hash" }?.value?.nonEmpty
    }

    /// `url` opens `page`: same host and path, with or without ".html"
    static func isPage(_ page: URL, _ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return isPage(page, components)
    }

    /// Same host and path, with or without ".html" (Cloudflare Pages serves its pages without the extension)
    private static func isPage(_ page: URL, _ components: URLComponents) -> Bool {
        guard components.host == page.host else { return false }
        let path = page.path
        return components.path == path || components.path + ".html" == path
    }
}
