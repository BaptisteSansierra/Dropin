//
//  UIColor+Random.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/5/26.
//

import UIKit

extension UIColor {
    
    static func random(range: ClosedRange<CGFloat> = CGFloat(0.25)...CGFloat(0.8)) -> UIColor {
        return UIColor(red: CGFloat.random(in: range),
                       green: CGFloat.random(in: range),
                       blue: CGFloat.random(in: range),
                       alpha: 1)
    }
}
