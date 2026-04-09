//
//  Icon+Codable.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/4/26.
//

import Foundation

extension Icon: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Icon(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid Icon")
        }
        self = value
    }
}
