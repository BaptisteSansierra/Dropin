//
//  Logger.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/3/26.
//

import Foundation

struct Log {
    
    enum VerboseLevel: Int {
        case debug = 0
        case info
        case warning
        case error
        case fatal
        
        var str: String {
            switch self {
                case .debug: "DBG"
                case .info: "NFO"
                case .warning: "WAR"
                case .error: "ERR"
                case .fatal: "FTL"
            }
        }

        var emo: String {
            switch self {
                case .debug: "🐛"
                case .info: "ℹ️"
                case .warning: "⚠️"
                case .error: "❌"
                case .fatal: "💀"
            }
        }
    }
    
    static let verboseLevel: VerboseLevel = .debug

    private init() {}
    
    static private func log(_ priority: VerboseLevel, _ message: String) {
        #if DEBUG
        guard priority.rawValue >= Log.verboseLevel.rawValue else { return }
        //print("[DRPN][\(priority.emo)\(priority.str)] \(message)")
        print("[DRPN][\(priority.emo)] \(message)")
        #endif
    }
    static private func log(_ priority: VerboseLevel, _ context: String, _ message: String) {
        #if DEBUG
        guard priority.rawValue >= Log.verboseLevel.rawValue else { return }
        //print("[DRPN][\(priority.emo)\(priority.str)] \(message)")
        print("[DRPN][\(context)] \(message)")
        #endif
    }

    static func custom(priority: VerboseLevel, context: String, _ message: String) {
        Log.log(priority, context, message)
    }
    
    static func debug(_ message: String, condition: Bool = true) {
        guard condition else { return }
        Log.log(.debug, message)
    }
    static func info(_ message: String) {
        Log.log(.info, message)
    }
    static func warning(_ message: String) {
        Log.log(.warning, message)
    }
    static func error(_ message: String) {
        Log.log(.error, message)
    }
    static func fatal(_ message: String) {
        Log.log(.fatal, message)
    }
}
