//
//  ImportPrepareViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

@MainActor
@Observable class ImportPrepareViewModel {

    let onCancel: () -> Void
    let onContinue: (URL, ImportSource, Bool, String) -> Void
    let resolveDestination: (ImportNavigationItem) -> AnyView
    
    var selectedSource: ImportSource = .dropin
    var tagImport: Bool = false
    var tagName: String = ""
    var tagErrorMessage: LocalizedStringKey?
    var tagNameProposal: String?
    var presentTagSanityError = false

    var url: URL {
        guard let url = coordinator.providedURL else {
            fatalError("missing coordinator url")
        }
        return url
    }

    var ext: ImportSupportedExtension {
        guard let sourceExt = ImportSupportedExtension(rawValue: url.pathExtension.lowercased()) else {
            // This have already been tested earlier, should not happen
            fatalError("unsupported extension")
        }
        return sourceExt
    }

    @ObservationIgnored var coordinator: ImportFlowCoordinator
    @ObservationIgnored private var availableTagName: AvailableTagName

    init(coordinator: ImportFlowCoordinator,
         availableTagName: AvailableTagName,
         onContinue: @escaping (URL, ImportSource, Bool, String) -> Void,
         onCancel: @escaping () -> Void,
         resolveDestination: @escaping (ImportNavigationItem) -> AnyView) {
        self.coordinator = coordinator
        self.availableTagName = availableTagName
        self.onContinue = onContinue
        self.onCancel = onCancel
        self.resolveDestination = resolveDestination
    }

    func fillAvailableTagName() async {
        tagName = await getAvailableTagName()
    }
    
    func importTagSanityCheck() async -> Bool {
        tagErrorMessage = nil
        guard tagImport else {
            // No need to check, import won't be tagged
            return true
        }
        // The import gets the name as stored
        tagName = tagName.trimmedName
        guard !tagName.isEmpty else {
            tagErrorMessage = "error.import.tag_import.missing"
            tagNameProposal = await getAvailableTagName()
            return false
        }
        do {
            let isAvailable = try await availableTagName.isAvailable(tagName)
            guard isAvailable else {
                tagErrorMessage = "error.import.tag_import.exists_\(tagName)"
                tagNameProposal = await getAvailableTagName(base: tagName)
                return false
            }
        } catch { /* theorically not reachable */ }
        return true
    }
    
    func didUpdateSelectedSource(_ newValue: ImportSource) {
        switch newValue {
            case .dropin: tagImport = false
            case .mapstr: tagImport = true
            case .google: tagImport = true
            case .unknown: tagImport = true
        }
        Task {
            await fillAvailableTagName()
        }
    }
    
    func selectDefaultSource() {
        // pre-select the source depending on the provided file extension
        switch ext {
            case .dropin:
                // .dropin must be a dropin file
                selectedSource = .dropin
            case .geojson:
                // .geoJSON could be anything, the user will choose
                selectedSource = .unknown
            case .json:
                // .json could be anything, the user will choose
                selectedSource = .unknown
        }
    }
    
    func next() {
        Task {
            guard await importTagSanityCheck() else {
                presentTagSanityError = true
                return
            }
            onContinue(url, selectedSource, tagImport, tagName)
        }
    }
    
    func cancel() {
        onCancel()
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
                case .google:
                    return try await availableTagName(base: selectedSource.description.lowercased())
                case .unknown:
                    return try await availableTagName(base: selectedSource.description.lowercased())
            }
        } catch {
            assertionFailure("an error occuured while getting available tag name: \(error)")
        }
        return String.randomColor()
    }
}
