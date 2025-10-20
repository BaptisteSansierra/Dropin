//
//  DataErrors.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation

enum DataError: Error {
    case notFound(msg: String)
    case duplicate(msg: String)
}
