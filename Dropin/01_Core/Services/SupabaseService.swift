//
//  SupabaseService.swift
//  Dropin

import Supabase
import Foundation

final class SupabaseService {
    let client: SupabaseClient

    struct DRPSupabaseLogger: SupabaseLogger {
        let verbose = false
        func log(message: SupabaseLogMessage) {
            guard verbose else { return }
            Log.custom(priority: .debug, context: "SUPABASE", "\(message.message) ___ \(message.additionalContext)")
        }
    }
    
    init() {
        let options = SupabaseClientOptions(auth: SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true),
                                            global: .init(logger: DRPSupabaseLogger()))
        client = SupabaseClient(supabaseURL: SupabaseConfig.url,
                                supabaseKey: SupabaseConfig.anonKey,
                                options: options)
    }
}
