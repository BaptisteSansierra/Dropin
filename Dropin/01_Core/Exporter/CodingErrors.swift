//
//  EncodingErrors.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation

enum CodingError: Error {
    case decodingUnknownVersion(version: Int)
}
