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
    
    static func random(square: CGFloat) -> UIImage {
        return random(size: CGSize(square: square))
    }
    
    static func random(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let renderedImage = renderer.image { context in
            for i in 0..<Int(size.width) {
                for j in 0..<Int(size.height) {
                    UIColor.random().setFill()
                    context.fill(CGRect(origin: CGPoint(x: Double(i), y: Double(j)), size: size))
                }
            }
        }
        return renderedImage
    }
    
    static func constant(size: CGSize, color: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let renderedImage = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return renderedImage
    }
    
    static func rdGeo(square: CGFloat) -> UIImage {
        let size = CGSize(square: square)
        let renderer = UIGraphicsImageRenderer(size: size)
        let renderedImage = renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            context.cgContext.setLineWidth(5)
            context.cgContext.setLineDash(phase: 0, lengths: [12, 5])
            UIColor.white.setStroke()
            var ofst = square * 0.2
            context.stroke(CGRect(origin: CGPoint(x: ofst, y: ofst),
                                  size: CGSize(square: square - 2 * ofst)))

            ofst = square * 0.35
            context.cgContext.setLineWidth(8)
            context.cgContext.setLineDash(phase: 0, lengths: [8, 3])
            UIColor.red.setStroke()
            context.stroke(CGRect(origin: CGPoint(x: ofst, y: ofst),
                                  size: CGSize(square: square - 2 * ofst)))

        }
        return renderedImage
    }
}
