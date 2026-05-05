//
//  ImportError.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

enum ImportError: Error {
    case unrecognizedFormat(String)
    case unsupported(String)
    case versionTooNew(Int)
    case corrupted(String)
}
