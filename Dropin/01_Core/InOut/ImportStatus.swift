//
//  ImportStatus.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/9/26.
//

import Foundation

@MainActor
@Observable class ImportStatus {
    
    enum Status: Equatable {
        case importing
        case complete
        case error(ImportError)

        static func == (lhs: ImportStatus.Status, rhs: ImportStatus.Status) -> Bool {
            switch lhs {
                case .importing: switch rhs { case .importing: return true; default: return false }
                case .complete: switch rhs { case .complete: return true; default: return false }
                case .error(_): switch rhs { case .error(_): return true; default: return false }
            }
        }
    }
    
    let filename: String
    let source: ImportSource                      // dropin / mapstr / ...
    private(set) var count: Int = 0               // places count
    private(set) var duplicateCount: Int = 0      // duplicated places count
    private(set) var createdPlaceCount: Int = 0   // created places count: may differ than count at the end: malformed / duplicate / ...
    private(set) var createdGroupCount: Int = 0   // groups count
    private(set) var createdTagCount: Int = 0     // tags count
    private(set) var progress: Int = 0
    private(set) var status: Status = .importing

    init(filename: String,
         source: ImportSource) {
        self.filename = filename
        self.source = source
    }
    
    func setCount(_ count: Int) {
        self.count = count
    }

    func setDuplicateCount(_ count: Int) {
        self.duplicateCount = count
    }

    func setCreatedPlaceCount(_ count: Int) {
        self.createdPlaceCount = count
    }

    func setCreatedGroupCount(_ count: Int) {
        self.createdGroupCount = count
    }
    
    func setCreatedTagCount(_ count: Int) {
        self.createdTagCount = count
    }
    
    func updateProgress(_ count: Int) {
        self.progress = count
    }
    
    func setError(_ error: ImportError) {
        self.status = .error(error)
    }
    
    func complete() {
        self.status = .complete
    }
}
