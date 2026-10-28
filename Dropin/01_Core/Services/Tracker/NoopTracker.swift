//
//  NoopTracker.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation

final class NoopTracker: TrackerProtocol, Sendable {

    func start() {
    }
    
    func setUser(id: String, email: String?) {
    }
    
    func resetUser() {
    }
    
    func captureWithFiles(_ error: any Error, urls: [URL]) {
    }
    
    func capture(_ message: String, authFlow: TrackerAuthFlow) {
    }
    
    func capture(_ message: String, flow: TrackerFlow) {
    }
}
