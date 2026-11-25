//
//  OpenFileError.swift
//  Dropin
//

import Foundation

/// Why a file opened from outside the app is refused
enum OpenFileError: UserFacingError, Equatable {
    case loggedOut
    case importInProgress
    case unsupported(String)   // file extension
    case unreadable(String)    // file name

    var messageTitle: LocalizedStringResource {
        switch self {
            case .loggedOut:
                "open_file.logged_out.title"
            case .importInProgress:
                "open_file.import_in_progress.title"
            case .unsupported, .unreadable:
                "import.error.title"
        }
    }
    var messageBody: LocalizedStringResource {
        switch self {
            case .loggedOut:
                "open_file.logged_out.body"
            case .importInProgress:
                "open_file.import_in_progress.body"
            case .unsupported(let ext):
                "import.error.unsupported_\(ext)"
            case .unreadable(let filename):
                "import.error.corrupted_\(filename)"
        }
    }
}
