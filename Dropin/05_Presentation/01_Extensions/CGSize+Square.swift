//
//  CGSize+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/5/26.
//

import Foundation

extension CGSize {
    
    init(square length: CGFloat) {
        self.init(width: length, height: length)
    }
}
