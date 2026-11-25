//
//  UserLanguage.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/11/26.
//

import Foundation
import Supabase

enum UserLanguage {
    /// Language the app is actually displayed in: always one the app supports (en/fr/es), follows the per-app language set in iOS Settings.
    static var app: String {
        code(Bundle.main.preferredLocalizations.first) ?? "en"
    }

    /// First language of the phone, supported or not. Stats only, never drives the emails.
    static var device: String {
        code(Locale.preferredLanguages.first) ?? "en"
    }

    /// Stored in the auth user metadata, read by the email templates / hook as `locale`.
    static var metadata: [String: AnyJSON] {
        ["locale": .string(app), "device_language": .string(device)]
    }

    /// "fr-FR" / "es-419" → "fr" / "es"
    private static func code(_ identifier: String?) -> String? {
        identifier.flatMap { Locale(identifier: $0).language.languageCode?.identifier }
    }
}
