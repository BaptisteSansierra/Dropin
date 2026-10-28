//
//  UserFacingError.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation

protocol UserFacingError: Error {
    var messageTitle: String { get }
    var messageBody: String { get }
}
