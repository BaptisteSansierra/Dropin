//
//  SupabaseConfig.swift
//  Dropin

import Foundation

enum SupabaseConfig {

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
