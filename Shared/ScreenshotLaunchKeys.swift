//
//  ScreenshotLaunchKeys.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/11/26.
//

/// Launch argument / environment keys between the DropinScreenshots UI tests and the app (cf. ScreenshotMode)
enum ScreenshotLaunchKeys {
    /// Launch argument: enables the screenshot mode
    static let argument = "-screenshots"
    /// Environment: absolute path of the .dropin seed file (lives in the test bundle)
    static let seedPath = "SCREENSHOT_SEED_PATH"
    /// Environment: absolute path of the .dropin file imported from Settings, bypassing the document picker
    static let importPath = "SCREENSHOT_IMPORT_PATH"
    /// Environment: map start region, "lat,lon,latDelta,lonDelta"
    static let hardStartRegion = "HARD_START_REGION"
    /// Environment: forced color scheme, "light" | "dark"
    static let colorScheme = "SCREENSHOT_COLOR_SCHEME"
}
