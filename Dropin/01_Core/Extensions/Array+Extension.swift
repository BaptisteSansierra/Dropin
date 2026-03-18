//
//  Array+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/3/26.
//

import Foundation

extension Array where Element == NavigationItem {
    
    func contains(_ kind: NavigationItem.Kind) -> Bool {
        contains { $0.kind == kind }
    }
}
