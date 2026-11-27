//
//  AppleNonce.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/11/26.
//
//  Sign in with Apple nonce ("number used once") : Apple gets the SHA256 of a random string, Supabase the raw string,
//  so it can check the ID token was issued for this request (replay protection).
//

import Foundation
import CryptoKit

enum AppleNonce {

    private static let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

    /// Random nonce from the system's secure generator
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes failed (\(status))")
        // charset has 64 characters: every byte maps to one without bias
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    /// Lowercase hex SHA256, the format Apple expects in `ASAuthorizationAppleIDRequest.nonce`
    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
