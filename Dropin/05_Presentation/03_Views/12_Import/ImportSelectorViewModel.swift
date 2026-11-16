//
//  ImportSelectorViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/11/26.
//

import SwiftUI

@MainActor
@Observable class ImportSelectorViewModel {
    var selectedSource: ImportSource = .dropin
    var tagImport: Bool = false
    var tagName: String = ""
    var pickFile = false
    var tagErrorMessage: LocalizedStringKey?
    var tagNameProposal: String?
    var presentTagSanityError = false
    
    @ObservationIgnored private let onContinue: (URL, ImportSource, Bool, String) -> Void
    @ObservationIgnored private let onCancel: () -> Void
    @ObservationIgnored let resolveDestination: (ImportNavigationItem) -> AnyView
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var coordinator: ImportFlowCoordinator
    @ObservationIgnored private var availableTagName: AvailableTagName
    
    init(_ appContainer: AppContainer,
         coordinator: ImportFlowCoordinator,
         availableTagName: AvailableTagName,
         onContinue: @escaping (URL, ImportSource, Bool, String) -> Void,
         onCancel: @escaping () -> Void,
         resolveDestination: @escaping (ImportNavigationItem) -> AnyView) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.availableTagName = availableTagName
        self.onContinue = onContinue
        self.onCancel = onCancel
        self.resolveDestination = resolveDestination
    }
    
    // MARK: - Navigation
    func importSheetContent() -> some View {
        let onPickedFile: (URL) -> Void = { url in
            self.onContinue(url, self.selectedSource, self.tagImport, self.tagName)
        }
        return ImportPicker(source: selectedSource, onPick: onPickedFile)
    }
    
    // MARK: - actions
    func fillAvailableTagName() async {
        tagName = await getAvailableTagName()
    }
    
    func next() {
#if DEBUG
        // Screenshots: overide action, import the test bundle file directly,
        //              the document picker can't be driven
        if ScreenshotMode.isOn {
            if let url = ScreenshotMode.mapstrImportURL {
                selectedSource = .mapstr
                tagImport = true
                tagName = "mapstr_01"
                onContinue(url, selectedSource, tagImport, tagName)
            } else if let url = ScreenshotMode.dropinImportURL {
                selectedSource = .dropin
                tagImport = true
                tagName = "dropin"
                onContinue(url, selectedSource, tagImport, tagName)
            } else {
                fatalError("Picking a file won't work with this target")
            }
        } else {
            presentFilePicker()
        }
#else
        presentFilePicker()
#endif
    }
            
    func cancel() {
        onCancel()
    }
    
    func importTagSanityCheck() async -> Bool {
        tagErrorMessage = nil
        guard tagImport else {
            // No need to check, import won't be tagged
            return true
        }
        guard !tagName.isTrimmedEmpty else {
            tagErrorMessage = "error.import.tag_import.missing"
            tagNameProposal = await getAvailableTagName()
            return false
        }
        do {
            let isAvailable = try await availableTagName.isAvailable(tagName)
            guard isAvailable else {
                tagErrorMessage = "error.import.tag_import.exists"
                tagNameProposal = await getAvailableTagName(base: tagName)
                return false
            }
        } catch { /* theorically not reachable */ }
        return true
    }
        
    // MARK: - private
    private func getAvailableTagName(base: String? = nil) async -> String {
        if let base = base {
            do {
                return try await availableTagName(base: base)
            } catch {
                assertionFailure("an error occuured while getting available tag name: \(error)")
            }
            return String.randomColor()
        }
        do {
            switch selectedSource {
                case .dropin:
                    return try await availableTagName(base: String(localized: "common.import").lowercased())
                case .mapstr:
                    return try await availableTagName(base: selectedSource.description.lowercased())
                default:
                    ()
            }
        } catch {
            assertionFailure("an error occuured while getting available tag name: \(error)")
        }
        return String.randomColor()
    }
    
    private func presentFilePicker() {
        Task {
            guard await importTagSanityCheck() else {
                presentTagSanityError = true
                return
            }
            pickFile.toggle()
        }
    }
}
