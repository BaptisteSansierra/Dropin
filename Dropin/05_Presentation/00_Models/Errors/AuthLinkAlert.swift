//
//  AuthLinkAlert.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/11/26.
//

import Foundation

/// Why an auth email link opened in the app couldn't be used
enum AuthLinkAlert: UserFacingError, Equatable {
    case expired(AuthLink.Kind)
    /// Password reset link opened while signed in
    case signedIn
    case notConnected
    case failed

    var messageTitle: LocalizedStringResource {
        switch self {
            case .expired:
                "auth.link.expired.title"
            case .signedIn:
                "auth.link.signed_in.title"
            case .notConnected, .failed:
                "auth.link.failed.title"
        }
    }
    
    var messageBody: LocalizedStringResource {
        switch self {
            case .expired(.emailConfirmation):
                "auth.link.expired.confirmation_body"
            case .expired(.passwordRecovery):
                "auth.link.expired.recovery_body"
            case .signedIn:
                "auth.link.signed_in.body"
            case .notConnected:
                "auth.link.failed.not_connected"
            case .failed:
                "delete_account.error.generic"
        }
    }
}
