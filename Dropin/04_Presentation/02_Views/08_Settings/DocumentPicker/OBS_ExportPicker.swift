//
//  ExportPicker.swift
//  Dropin
//
//  Created by baptiste sansierra on 28/4/26.
//

/*
import SwiftUI
import UniformTypeIdentifiers

struct ExportPicker: UIViewControllerRepresentable {

    private let localDoc: URL
    private let onPick: (URL) -> Void
    
    init(localDoc: URL, onPick: @escaping (URL) -> Void) {
        self.localDoc = localDoc
        self.onPick = onPick
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [localDoc], asCopy: false)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
*/
