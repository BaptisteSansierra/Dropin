//
//  ImportOverlayView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/11/26.
//

import SwiftUI

/// Window displayed over the main window to handle import feature
struct ImportOverlayView: View {

    @State private var viewModel: ImportOverlayViewModel

    init(viewModel: ImportOverlayViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            ImportStatusView(importStatus: $viewModel.importStatus,
                             cancelCb: cancelImport,
                             closeCb: closeImport)
        }
        .fullScreenCover(isPresented: $viewModel.presentPrepareView, content: {
            viewModel.createImportPrepareView()
                // A file refused while preparing: the cover is presenting, the alert must come from it
                .alertError(error: $viewModel.openFileError)
        })
        .fullScreenCover(isPresented: $viewModel.presentBrowseView, content: {
            viewModel.createImportSelectorView()
        })
        .alertError(error: $viewModel.openFileError)
        .onChange(of: viewModel.openFileError) { _, error in
            // Once the error popup is dismissed, dismiss the window, unless the alert was over a running import
            if error == nil, viewModel.importStatus == nil { viewModel.dismiss() }
        }
        .task {
        }
    }
    
    private func cancelImport() {
        viewModel.cancelImport()
    }
    
    private func closeImport() {
        viewModel.dismiss(waitForAnimation: false)
    }
}
