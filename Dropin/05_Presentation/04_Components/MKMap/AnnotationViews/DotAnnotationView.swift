//
//  DotAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/9/26.
//

import MapKit
import UIKit

/// Cheap, non-interactive marker : a plain colored dot with no
/// Used to display the whole set of places
class DotAnnotationView: MKAnnotationView {

    private static let size: CGFloat = 8

    private let dot = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isEnabled = false
        canShowCallout = false
        // Dots are the permanent, always-visible base layer — never collision-hidden,
        // by themselves or against a promoted pin sharing the same coordinate.
        collisionMode = .none
        zPriority = .min   // always draw below a pin sharing the same coordinate

        let size = Self.size
        bounds = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = .zero

        dot.frame = bounds
        dot.layer.cornerRadius = size / 2
        dot.layer.borderColor = UIColor.white.cgColor
        dot.layer.borderWidth = 1
        addSubview(dot)
    }

    func configure(color: UIColor) {
        dot.backgroundColor = color
    }
}
