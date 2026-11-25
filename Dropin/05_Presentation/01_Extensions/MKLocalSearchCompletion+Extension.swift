//
//  MKLocalSearchCompletion+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/11/26.
//

import MapKit

extension MKLocalSearchCompletion {
    func isIdentical(to other: MKLocalSearchCompletion) -> Bool {
        title == other.title && subtitle == other.subtitle
    }
}
