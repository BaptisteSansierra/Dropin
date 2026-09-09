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
    let source: ImportSource              // dropin / mapstr / ...
    private(set) var count: Int           // places count
    private(set) var duplicateCount: Int  // duplicated places count
    private(set) var groupCount: Int      // groups count
    private(set) var tagCount: Int        // tags count
    private(set) var progress: Int
    private(set) var status: Status

    init(filename: String,
         source: ImportSource) {
        self.filename = filename
        self.source = source
        count = 0
        duplicateCount = 0
        groupCount = 0
        tagCount = 0
        progress = 0
        status = .importing
    }
    
    func setCount(_ count: Int) {
        self.count = count
    }

    func setDuplicateCount(_ count: Int) {
        self.duplicateCount = count
    }

    func setGroupCount(_ count: Int) {
        self.groupCount = count
    }
    
    func setTagCount(_ count: Int) {
        self.tagCount = count
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
