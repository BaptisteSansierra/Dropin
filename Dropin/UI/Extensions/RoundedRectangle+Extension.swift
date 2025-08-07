//
//  RoundedRectangle+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI

extension RoundedRectangle {
    
    init(cornerSize: CGFloat) {
        self.init(cornerSize: CGSize(width: cornerSize, height: cornerSize))
    }
}
