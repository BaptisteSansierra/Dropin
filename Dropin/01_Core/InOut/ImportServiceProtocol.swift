//
//  ImportServiceProtocol.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
protocol ImportServiceProtocol {
    func execute(_ url: URL) async throws
}
