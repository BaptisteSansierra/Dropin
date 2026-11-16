//
//  ImportPresenter.swift
//  Dropin
//

import SwiftUI

@MainActor
protocol ImportsEventProvider {
    var lastImportedAt: Date? { get }
}

/// Presents the import flow (file opened from outside the app, or browsing from Settings) in its own window,
/// over whatever the app window is presenting
@MainActor
@Observable final class ImportPresenter: ImportsEventProvider {

    // MARK: - public state
    private(set) var lastImportedAt: Date?
    
    // MARK: - public properties
    /// Set once by DropinAppModel: injected in the overlay window's environment
    @ObservationIgnored var appSettings: AppSettings?
    @ObservationIgnored var isImporting: Bool { window?.isImporting ?? false }

    // MARK: - private properties
    @ObservationIgnored private unowned let appContainer: AppContainer
    /// Created on first use, hidden while idle
    @ObservationIgnored private var window: ImportOverlayWindow?

    init(appContainer: AppContainer) {
        self.appContainer = appContainer
    }

    // MARK: - public methods
    /// File opened from outside the app (local copy), the user prepares its import
    func presentFile(_ url: URL) {
        overlay?.present(url)
    }

    /// Opened file refused
    func presentError(_ error: OpenFileError) {
        overlay?.present(error)
    }

    /// Import from Settings: the user chooses the source, then the file
    func presentBrowse() {
        guard !isImporting else {
            presentError(.importInProgress)
            return
        }
        overlay?.present()
    }

    // MARK: - Private
    private var overlay: ImportOverlayWindow? {
        if window == nil, let scene = Self.activeWindowScene {
            guard let appSettings else {
                assertionFailure("ImportPresenter.appSettings must be set before presenting")
                return nil
            }
            window = ImportOverlayWindow(windowScene: scene,
                                         appContainer: appContainer,
                                         appSettings: appSettings,
                                         onImportEnded: { self.lastImportedAt = Date() })
        }
        return window
    }

    private static var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
