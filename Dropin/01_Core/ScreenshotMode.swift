//
//  ScreenshotMode.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/11/26.
//

#if DEBUG
import Foundation
import MapKit
import SwiftUI

/// App launched by the DropinScreenshots UI tests (`-screenshots`):
/// in-memory store seeded from a .dropin file, local John Doe session, no Sentry, no network.
enum ScreenshotMode {
    static let isOn = ProcessInfo.processInfo.arguments.contains(ScreenshotLaunchKeys.argument)

    /// Absolute path of the seed file, set by the test (it lives in the test bundle)
    static var seedURL: URL? {
        ProcessInfo.processInfo.environment[ScreenshotLaunchKeys.seedPath].map { URL(fileURLWithPath: $0) }
    }

    /// Absolute path of the file imported from Settings instead of picking one (it lives in the test bundle)
    static var importURL: URL? {
        ProcessInfo.processInfo.environment[ScreenshotLaunchKeys.importPath].map { URL(fileURLWithPath: $0) }
    }
    
    static var colorScheme: ColorScheme? {
        switch ProcessInfo.processInfo.environment[ScreenshotLaunchKeys.colorScheme] {
            case "dark": .dark
            case "light": .light
            default: nil
        }
    }
}

extension UserSession {
    static let johnDoe = UserSession(userId: UUID(uuidString: "00000000-0000-0000-0000-00000000D0E0")!,
                                     email: "john.doe@proton.me")   // same as StubProfileService
}
#endif
