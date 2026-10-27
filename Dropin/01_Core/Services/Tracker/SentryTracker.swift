//
//  SentryTracker.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation
import Sentry

/// SentryTracker centralize all the sentry calls
/// testability + swapability
final class SentryTracker: TrackerProtocol, Sendable {
    
    func start() {
        SentrySDK.start { options in
            options.dsn = AppConfig.Sentry.dsn
            options.debug = true // Enabled debug when first installing is always helpful
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
#if DEBUG
            options.tracesSampleRate = 1.0
#else
            options.tracesSampleRate = 0.1
#endif
        }
    }

    func setUser(id: String, email: String?) {
        let user = Sentry.User(userId: id)
        user.email = email
        SentrySDK.setUser(user)
    }

    func resetUser() {
        SentrySDK.setUser(nil)
    }

    // MARK: captures
    func captureWithFiles(_ error: Error, urls: [URL]) {
        SentrySDK.capture(error: error) { scope in
            scope.setLevel(.error)
            for url in urls {
                scope.addAttachment(Attachment(path: url.path, filename: url.lastPathComponent))
            }
        }
    }
    
    func capture(_ message: String, authFlow: TrackerAuthFlow) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(.error)
            scope.setTag(value: authFlow.rawValue, key: TrackerTag.authFlow.rawValue)
        }
    }
}
