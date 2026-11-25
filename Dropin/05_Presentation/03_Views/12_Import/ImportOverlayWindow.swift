//
//  ImportOverlayWindow.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

/// Window above the app window: presents the import preparation of a file opened from outside the app, or why it's refused,
final class ImportOverlayWindow: UIWindow {

    private let appContainer: AppContainer
    private let appSettings: AppSettings
    private let onImportEnded: () -> Void
    /// View model of the current presentation, replaced by each `present`
    private var viewModel: ImportOverlayViewModel?

    var isImporting: Bool { viewModel?.isImporting ?? false }
    
    init(windowScene: UIWindowScene,
         appContainer: AppContainer,
         appSettings: AppSettings,
         onImportEnded: @escaping () -> Void ) {
        self.appContainer = appContainer
        self.appSettings = appSettings
        self.onImportEnded = onImportEnded
        super.init(windowScene: windowScene)
        windowLevel = .normal + 1   // the app window presents its sheets and alerts within itself
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - public methods
    /// called to import a specific file
    func present(_ url: URL) {
        guard let _ = ImportSupportedExtension(rawValue: url.pathExtension.lowercased()) else {
            present(.unsupported(url.pathExtension))
            return
        }
        createHost(flowMode: .openFile(IdentifiableURL(url: url)))
        show()
    }

    /// called when an error occured with the provided file
    func present(_ error: OpenFileError) {
        // Over a running import: alert on top of it, rebuilding the host would drop its progress
        if let viewModel, viewModel.isImporting {
            viewModel.openFileError = error
            return
        }
        createHost(flowMode: .openFileError(error))
        show()
    }

    /// called when browsing a file is needed
    func present() {
        createHost(flowMode: .browse)
        show()
    }

    func cancelImport() {
        viewModel?.cancelImport()
        viewModel?.dismiss(waitForAnimation: false)
    }

    // MARK: - Private methods
    private func createHost(flowMode: ImportFlowCoordinator.Mode) {
        let viewModel = appContainer.createImportOverlayViewModel(coordinatorMode: flowMode,
                                                                  onIdle: { [weak self] in self?.hideIfIdle() },
                                                                  onImportEnded: onImportEnded)
        self.viewModel = viewModel
        let host = UIHostingController(rootView: ImportOverlayView(viewModel: viewModel)
            .environment(appSettings))
        host.view.backgroundColor = .clear
        rootViewController = host
    }
    
    private func show() {
        guard isHidden else { return }
        makeKeyAndVisible()
    }

    /// Once the preparation view or the alert is dismissed: give the touches and the keyboard back to the app window
    private func hideIfIdle() {
        guard !isHidden else { return }
        isHidden = true
        windowScene?.windows.first { $0 !== self && !$0.isHidden }?.makeKey()
    }
}
