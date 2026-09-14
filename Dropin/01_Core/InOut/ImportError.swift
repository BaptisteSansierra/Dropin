//
//  ImportError.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

enum ImportError: Error, Equatable, Sendable {
    case unrecognizedFormat(ImportSource,
                            String,
                            String)     // The file format is not the expected one (ex: mapstr import expects 'geojson' extension). Takes source/expected extension/given extension
    case unsupported(String)            // Source is not handled. This shouldn't happen
    case versionTooNew(Int)             // This version is not handled (apply to dropin files)
    case corrupted(String)              // JSON decoder failed
    case emptyFile                      // The file contains no places
    case canceled                       // User canceled the import (This one is never thrown but set in ImportStatus)
    case markerExists(String)           // The import marker already exists
    case unexpectedError(Error)         // Error comes from elsewhere

    var localizedDescription: String {
        switch self {
            case .unrecognizedFormat(let source, let expectedExt, let givenExt):
                String(localized: "import.error.unrecognized_format_\(source.description)_\(expectedExt)_\(givenExt)")
            case .unsupported(let source):
                String(localized: "import.error.unsupported_\(source)")
            case .versionTooNew(let version):
                String(localized: "import.error.version_too_new_\(version)")
            case .corrupted(let reason):
                String(localized: "import.error.corrupted_\(reason)")
            case .emptyFile:
                String(localized: "import.error.empty_file")
            case .canceled:
                String(localized: "import.error.canceled")
            case .markerExists(let markerName):
                String(localized: "import.error.mapstr_marker_exists_\(markerName)")
            case .unexpectedError(let error):
                String(localized: "import.error.unexpected_\(error.localizedDescription)")
        }
    }
    
    static func == (lhs: ImportError, rhs: ImportError) -> Bool {
        switch (lhs, rhs) {
            case (.unrecognizedFormat, .unrecognizedFormat):
                return true
            case (.unsupported, .unsupported):
                return true
            case (.versionTooNew, .versionTooNew):
                return true
            case (.corrupted, .corrupted):
                return true
            case (.emptyFile, .emptyFile):
                return true
            case (.canceled, .canceled):
                return true
            case (.markerExists, .markerExists):
                return true
            case (.unexpectedError, .unexpectedError):
                return true
            default:
                return false
        }
    }
}
