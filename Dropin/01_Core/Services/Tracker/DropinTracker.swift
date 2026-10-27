//
//  DropinTracker.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation
import Sentry

/// DropinTracker allows to swap easily from a tracker to another
final class DropinTracker: TrackerProtocol, Sendable {

    enum Mode {
        case sentry
        case noop
    }
    
    static let shared = DropinTracker()
    
    private let backend: TrackerProtocol
        
    private init() {
        #if DEBUG
        //backend = NoopTracker()
        backend = SentryTracker()
        #else
        backend = SentryTracker()
        #endif
    }
    
    func start() {
        backend.start()
    }
    
    func setUser(id: String, email: String?) {
        backend.setUser(id: id, email: email)
    }
    
    func resetUser() {
        backend.resetUser()
    }
    
    func captureWithFiles(_ error: any Error, urls: [URL]) {
        backend.captureWithFiles(error, urls: urls)
    }
    
    func capture(_ message: String, authFlow: TrackerAuthFlow) {
        backend.capture(message, authFlow: authFlow)
    }
}
