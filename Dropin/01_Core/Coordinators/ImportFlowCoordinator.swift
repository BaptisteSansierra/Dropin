//
//  ImportFlowCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/11/26.
//

import SwiftUI

@MainActor
@Observable class ImportFlowCoordinator: NavigationCoordinator {
    
    var path: [ImportNavigationItem] = [] {
        didSet {
        }
    }
        
    enum Mode {
        case openFile(IdentifiableURL)
        case browse
        case openFileError(OpenFileError)
    }
    
    // Computed
    var providedURL: URL? {
        switch mode {
            case .openFile(let url):
                return url.url
            default:
                return nil
        }
    }

    // Internal
    @ObservationIgnored private(set) var mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
    }

    // MARK: navigation methods
    func pushCategoryMapper() {
        push(.categoryMapper)
    }
    
    private func push(_ item: ImportNavigationItem) {
        path.append(item)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum ImportNavigationItem: Hashable {
    case categoryMapper
}
