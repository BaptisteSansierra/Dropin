//
//  AppErrors.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/25.
//

import Foundation

enum AppError: Error {
    case notImplemented
    case sdNotFound(msg: String)
    case sdDuplicate(msg: String)
}

