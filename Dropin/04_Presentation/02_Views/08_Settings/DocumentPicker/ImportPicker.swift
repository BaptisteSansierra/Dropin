//
//  ImportPicker.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportPicker: UIViewControllerRepresentable {

    private let onPick: (URL) -> Void
    private let source: ImportSource
    
    private var pickedType: [UTType] {
        switch source {
            case .dropin:
                guard let dropinType = UTType(DropinApp.strings.exportUTTypeId) else {
                    assertionFailure("unknown dropin file type")
                    return []
                }
                return [dropinType]
            case .mapstr, .google:
                return [.geoJSON]
            default:
                return []
        }
    }
    
    init(source: ImportSource, onPick: @escaping (URL) -> Void) {
        self.source = source
        self.onPick = onPick
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: pickedType, asCopy: false)
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
