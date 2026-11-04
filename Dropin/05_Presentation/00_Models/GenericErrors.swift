//
//  GenericErrors.swift
//  Dropin
//
//  Created by baptiste sansierra on 28/10/26.
//

import Foundation

enum GenericError: UserFacingError {
    case fetchDatabase(Error)
    case updateDatabase(Error)
    case encoding(Error)
    case noDiskSpace(Error)
    case unexpected(Error)

    var messageTitle: LocalizedStringResource {
        switch self {
            case .fetchDatabase:
                "error.fetch_database.title"
            case .updateDatabase:
                "error.update_database.title"
            case .encoding:
                "error.encoding.title"
            case .noDiskSpace:
                "error.disk_space.title"
            case .unexpected:
                "error.unexpected.title"
        }
    }
    var messageBody: LocalizedStringResource {
        switch self {
            case .fetchDatabase(let error):
                "error.fetch_database.body_\(error.localizedDescription)"
            case .updateDatabase(let error):
                "error.update_database.body_\(error.localizedDescription)"
            case .encoding(let error):
                "error.encoding.body_\(error.localizedDescription)"
            case .noDiskSpace(let error):
                "error.disk_space.body_\(error.localizedDescription)"
            case .unexpected(let error):
                "error.unexpected.body_\(error.localizedDescription)"
        }
    }
}

