//
//  Tracker.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation

enum TrackerTag: String {
    case authFlow
    case flow
}

enum TrackerAuthFlow: String {
    case signin
    case signup
    case restore_session
}

enum TrackerFlow: String {
    case profile
}

protocol TrackerProtocol: Sendable {
    func start()
    func setUser(id: String, email: String?)
    func resetUser()
    func captureWithFiles(_ error: Error, urls: [URL])
    func capture(_ message: String, authFlow: TrackerAuthFlow)
    func capture(_ message: String, flow: TrackerFlow)
}
