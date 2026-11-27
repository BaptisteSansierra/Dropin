//
//  AppleReauthorization.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/11/26.
//
//  Shows the Apple sheet again to get a fresh authorization code: deleting a Sign in with Apple account
//  needs one, the backend exchanges it for a token and revokes it (App Store guideline 5.1.1(v)).
//

import AuthenticationServices
import UIKit

@MainActor
protocol AppleReauthorizationProtocol {
    /// Authorization code of a new Apple request (no scopes, single use, valid 5 minutes).
    /// Throws `ASAuthorizationError.canceled` when the sheet is dismissed
    func authorizationCode() async throws -> String
}

@MainActor
final class AppleReauthorization: NSObject, AppleReauthorizationProtocol {

    private var continuation: CheckedContinuation<String, Error>?
    /// Retained while the sheet is shown
    private var controller: ASAuthorizationController?

    func authorizationCode() async throws -> String {
        guard continuation == nil else {
            assertionFailure("Apple reauthorization already in progress")
            throw ASAuthorizationError(.failed)
        }
        let controller = ASAuthorizationController(authorizationRequests: [ASAuthorizationAppleIDProvider().createRequest()])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<String, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
    }
}

extension AppleReauthorization: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        let code = (authorization.credential as? ASAuthorizationAppleIDCredential)?
            .authorizationCode
            .flatMap { String(data: $0, encoding: .utf8) }
        Task { @MainActor in
            if let code {
                finish(.success(code))
            } else {
                Log.error("AppleReauthorization: Apple credential without authorization code")
                finish(.failure(ASAuthorizationError(.invalidResponse)))
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        Task { @MainActor in
            finish(.failure(error))
        }
    }
}

extension AppleReauthorization: ASAuthorizationControllerPresentationContextProviding {

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
