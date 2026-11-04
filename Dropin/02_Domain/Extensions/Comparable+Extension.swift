//
//  Comparable+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/4/26.
//

import Foundation

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
