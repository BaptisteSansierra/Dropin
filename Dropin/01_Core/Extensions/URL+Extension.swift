//
//  URL+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/26.
//

import Foundation

extension URL {
    var displayHost: String? {
        guard let host = host(percentEncoded: false) else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
