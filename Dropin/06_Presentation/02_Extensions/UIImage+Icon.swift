//
//  UIImage+Icon.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/3/26.
//

import UIKit

extension UIImage {
    
    convenience init?(icon: Icon) {
        switch icon {
            case .sf:
                self.init(systemName: icon.name)
            case .fa:
                // If using Font Awesome as images in Assets
                self.init(named: icon.name)
        }
    }
}
