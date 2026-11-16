//
//  DropinScreenshots.swift
//  DropinScreenshots
//
//  Created by baptiste sansierra on 4/11/26.
//

import XCTest

private enum Region {
    static let lisbon = "38.71108482247233,-9.137567732050831,0.02649615024206753,0.020133175667885084"
    /// Same span as lisbon, centered on Golden Tart Bakery (Belém is out of the lisbon region)
    static let belem = "38.6984,-9.2008,0.02649615024206753,0.020133175667885084"
    /// Same span as lisbon, centered on the quick create long press point
    static let bellavista = "38.67686943509181,-9.206906491199476,0.02649615024206753,0.020133175667885084"
}

private enum ImportSource { case dropin, mapstr }

/// Attachment names, exported as file names by scripts/screenshots.sh (prefix = App Store order)
private enum Shot: String {
    case map = "places.map"
    case mapDark = "places.map.dark"
    case mapFiltered = "places.map.filtered"
    case filterOff = "places.filter.off"
    case filterOn = "places.filter.on"
    case list = "places.list"
    case mapPlaceDetails = "places.place.details"
    case importMapstr = "settings.import.mapstr"
    case importMapstrMapper = "settings.import.mapstr.mapper"
    case importDropin = "settings.import.dropin"
    case mapQuickCreate = "places.map.quickcreate"
}

/// Seed data names (lisbon_screenshot_seed.dropin), not localized
private enum Seed {
    static let filteredCategories = ["Restaurant"]
    static let filteredTags = ["Terrace", "To try"]
    static let detailsPlace = "Golden Tart Bakery"
    static let quickCreateName = "Bellavista"
    static let quickCreateCategory = "Hotel"
    static let quickCreateTags = ["Dog friendly", "Garden"]
}

final class DropinScreenshots: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMap() throws {
        let app = try launch(appearance: .light)
        waitForMap(app)
        snapshot(app, .map)
    }

    @MainActor
    func testMapDark() throws {
        let app = try launch(appearance: .dark)
        waitForMap(app)
        snapshot(app, .mapDark)
    }

    @MainActor
    func testList() throws {
        let app = try launch(appearance: .light)
        waitForMap(app)
        element(app, AccessibilityID.Places.listTab).tap()
        XCTAssertTrue(element(app, AccessibilityID.Places.list).waitForExistence(timeout: 5))
        sleep(1)   // thumbnails
        snapshot(app, .list)
    }

    @MainActor
    func testFilter() throws {
        let app = try launch(appearance: .light)
        waitForMap(app)

        element(app, AccessibilityID.Places.filterButton).tap()
        let sheet = element(app, AccessibilityID.PlaceFilter.sheet)
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        sleep(1)   // sheet presentation
        snapshot(app, .filterOff)

        for name in Seed.filteredCategories {
            let chip = sheet.staticTexts[name]
            XCTAssertTrue(chip.waitForExistence(timeout: 5), "missing seed category '\(name)'")
            chip.tap()
        }
        for name in Seed.filteredTags {
            let chip = sheet.staticTexts[name]
            XCTAssertTrue(chip.waitForExistence(timeout: 5), "missing seed tag '\(name)'")
            chip.tap()
        }
        
        let tagPolicy = sheet.segmentedControls[AccessibilityID.PlaceFilter.tagPolicy]
        XCTAssertTrue(tagPolicy.waitForExistence(timeout: 5))
        tagPolicy.buttons.element(boundBy: 1).tap()   // .all
        
        snapshot(app, .filterOn)

        element(app, AccessibilityID.PlaceFilter.apply).tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
        sleep(2)   // pins update
        snapshot(app, .mapFiltered)
    }

    @MainActor
    func testSettingsImportMapstr() throws {
        let file = try XCTUnwrap(Bundle(for: Self.self).path(forResource: "mapstr_germany_30", ofType:"geojson"))
        let app = try launch(appearance: .light, importSource: (.mapstr, file))
        waitForMap(app)
        try goImport(app)
        
        // Select tag rows to convert
        let tagRow6 = element(app, "\(AccessibilityID.MapstrTagMapper.tagRow)_\(6)")
        let tagRow8 = element(app, "\(AccessibilityID.MapstrTagMapper.tagRow)_\(8)")
        let tagRow10 = element(app, "\(AccessibilityID.MapstrTagMapper.tagRow)_\(10)")
        XCTAssertTrue(tagRow10.waitForExistence(timeout: 5))
        tagRow10.tap()
        tagRow8.tap()
        tagRow6.tap()
        
        let scrollView = element(app, AccessibilityID.MapstrTagMapper.scrollView)
        scrollView.swipeDown(velocity: .fast)

        sleep(2) // wait for the scroll indicator to disappear
        snapshot(app, .importMapstrMapper)

        let continueBt = element(app, AccessibilityID.MapstrTagMapper.continueButton)
        XCTAssertTrue(continueBt.waitForExistence(timeout: 0))
        continueBt.tap()


        // Snapshot ImportResultView
        XCTAssertTrue(element(app, AccessibilityID.ImportStatus.complete).waitForExistence(timeout: 30))
        sleep(1)
        snapshot(app, .importMapstr)
    }
    
    @MainActor
    func testSettingsImportDropin() throws {
        let file = try XCTUnwrap(Bundle(for: Self.self).path(forResource: "barcelona_demo", ofType: "dropin"))
        let app = try launch(appearance: .light, importSource: (.dropin, file))
        waitForMap(app)
        try goImport(app)
        // Snapshot ImportResultView
        XCTAssertTrue(element(app, AccessibilityID.ImportStatus.complete).waitForExistence(timeout: 30))
        sleep(1)
        snapshot(app, .importDropin)
    }

    @MainActor
    func testMapPlaceDetails() throws {
        let app = try launch(appearance: .light, region: Region.belem)
        waitForMap(app)

        // Pin label: unique among StaticTexts (Apple POIs with the same name are `Other`)
        let pin = element(app, AccessibilityID.Places.map).staticTexts[Seed.detailsPlace]
        XCTAssertTrue(pin.waitForExistence(timeout: 5), "'\(Seed.detailsPlace)' not visible in Region.belem")
        pin.tap()

        XCTAssertTrue(element(app, AccessibilityID.PlaceSheet.root).waitForExistence(timeout: 5))
        sleep(2)   // sheet presentation + didSelect zoom/center
        snapshot(app, .mapPlaceDetails)
    }

    @MainActor
    func testMapQuickCreate() throws {
        let app = try launch(appearance: .light, region: Region.bellavista)
        waitForMap(app)

        // Region.bellavista is centered on the place to create: long press the middle of the map
        element(app, AccessibilityID.Places.map)
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 1.2)
        let sheet = element(app, AccessibilityID.QuickCreate.sheet)
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))

        let name = element(app, AccessibilityID.PlaceHeader.name)
        name.tap()
        name.typeText(Seed.quickCreateName)

        // Category: selecting a row dismisses the selector
        element(app, AccessibilityID.QuickCreate.chooseCategory).tap()
        let category = app.buttons.staticTexts[Seed.quickCreateCategory].firstMatch
        XCTAssertTrue(category.waitForExistence(timeout: 5), "missing seed category '\(Seed.quickCreateCategory)'")
        category.tap()
        XCTAssertTrue(category.waitForNonExistence(timeout: 5))

        // Tags: no close button, dismissed with a swipe
        element(app, AccessibilityID.QuickCreate.addTags).tap()
        let tagSelector = element(app, AccessibilityID.TagSelector.sheet)
        XCTAssertTrue(tagSelector.waitForExistence(timeout: 5))
        for tag in Seed.quickCreateTags {
            let chip = tagSelector.staticTexts[tag]
            XCTAssertTrue(chip.waitForExistence(timeout: 5), "missing seed tag '\(tag)'")
            chip.tap()
        }
        tagSelector.swipeDown(velocity: .fast)
        XCTAssertTrue(tagSelector.waitForNonExistence(timeout: 5))

        sleep(1)   // sheet settles, address lookup
        snapshot(app, .mapQuickCreate)
    }

    // MARK: - Navigation
    @MainActor
    private func goSettings(_ app: XCUIApplication) throws {
        element(app, AccessibilityID.Navigation.burger).tap()
        sleep(1)
        element(app, AccessibilityID.Sidebar.settings).tap()
    }
    
    @MainActor
    private func goImport(_ app: XCUIApplication) throws {
        try goSettings(app)
        
        let importMenu = element(app, AccessibilityID.Settings.importButton)
        XCTAssertTrue(importMenu.waitForExistence(timeout: 5))
        importMenu.tap()

        // next button is configured to automatically launch the import for the provided file + source
        // bypassing the file picker which cannot be handled here
        let importSelectorContinue = element(app, AccessibilityID.ImportSelector.continueButton)
        XCTAssertTrue(importSelectorContinue.waitForExistence(timeout: 5))
        importSelectorContinue.tap()
    }
    
    // MARK: - helpers
    @MainActor
    private func launch(appearance: XCUIDevice.Appearance,
                        region: String = Region.lisbon,
                        importSource: (ImportSource, String)? = nil) throws -> XCUIApplication {
        let seed = try XCTUnwrap(Bundle(for: Self.self).path(forResource: "lisbon_screenshot_seed", ofType: "dropin"))
        let app = XCUIApplication()
        app.launchArguments += [ScreenshotLaunchKeys.argument,
                                "-space.current", ""]   // UserDefaults override: main space, whatever the simulator stored
        app.launchEnvironment[ScreenshotLaunchKeys.seedPath] = seed
        app.launchEnvironment[ScreenshotLaunchKeys.hardStartRegion] = region
        app.launchEnvironment[ScreenshotLaunchKeys.colorScheme] = appearance == .dark ? "dark" : "light"
        if let importSource {
            switch importSource.0 {
                case .dropin:
                    app.launchEnvironment[ScreenshotLaunchKeys.dropinImportPath] = importSource.1
                case .mapstr:
                    app.launchEnvironment[ScreenshotLaunchKeys.mapstrImportPath] = importSource.1
            }
        }
        app.launch()
        return app
    }

    /// Any element type: a UIViewRepresentable may not be exposed as `.other`
    @MainActor
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    private func waitForMap(_ app: XCUIApplication) {
        XCTAssertTrue(element(app, AccessibilityID.Places.map).waitForExistence(timeout: 15))
        sleep(2)   // map tiles render after the view exists
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ shot: Shot) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = shot.rawValue
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
