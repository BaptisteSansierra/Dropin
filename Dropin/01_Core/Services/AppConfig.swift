//
//  AppConfig.swift
//  Dropin
//
//  Build-time configuration values sourced from Config.xcconfig via Info.plist
//  substitution. Not secrets (Supabase's anon key and Sentry's DSN are both meant
//  to be client-embedded); just kept out of source so they're swappable per build
//  without a code change.
//

import Foundation

enum AppConfig {

    enum Supabase {
        static var url: URL {
            guard let str = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
                  !str.isEmpty,
                  let url = URL(string: str) else {
                fatalError("SUPABASE_URL missing or invalid — fill in Config.xcconfig")
            }
            Log.debug("Supabase URL: \(url)")
            return url
        }

        static var anonKey: String {
            guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
                  !key.isEmpty else {
                fatalError("SUPABASE_ANON_KEY missing — fill in Config.xcconfig")
            }
            Log.debug("Supabase ANON Key: \(key)")
            return key
        }
    }

    enum Sentry {
        static var dsn: String {
            guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String,
                  !dsn.isEmpty else {
                fatalError("SENTRY_DSN missing — fill in Config.xcconfig")
            }
            return dsn
        }
    }

    #if DEBUG
    /// Sign in / sign up prefill. Config.xcconfig, Debug configuration only (empty in Release builds);
    /// the account is picked with DEBUG_SIGNIN_ACCOUNT. Empty strings when not configured.
    enum DebugCredentials {
        static var email: String { value("DEBUG_SIGNIN_EMAIL") }
        static var password: String { value("DEBUG_SIGNIN_PASSWORD") }

        /// "<prefix><random><suffix>", e.g. name+k3x9q2@gmail.com; empty when prefix/suffix aren't configured
        static func signUpEmail() -> String {
            let prefix = value("DEBUG_SIGNUP_EMAIL_PREFIX"), suffix = value("DEBUG_SIGNUP_EMAIL_SUFFIX")
            guard !prefix.isEmpty, !suffix.isEmpty else { return "" }
            let random = UUID().uuidString.prefix(6).lowercased()
            return "\(prefix)\(random)\(suffix)"
        }

        private static func value(_ key: String) -> String {
            Bundle.main.infoDictionary?[key] as? String ?? ""
        }
    }
    #endif
}
