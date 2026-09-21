//
//  PlaceIconLayerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit
import SwiftUI

/// UIKit port of `PlaceIconView` (SwiftUI) — a circle-in-circle badge (`textPrimary`
/// outer, `backgroundPrimary` inner, 2pt smaller) with a centered icon. Shared by
/// `PlacePinAnnotationLayerView` and `PlaceRectAnnotationLayerView` for their
/// `iconExtra` badge, same as the SwiftUI originals both compose `PlaceIconView`.
final class PlaceIconLayerView: UIView {

    private let outer = CAShapeLayer()
    private let inner = CAShapeLayer()
    private let iconView = UIImageView()

    private var shadow: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.addSublayer(outer)
        layer.addSublayer(inner)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .label
        addSubview(iconView)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateColors()
        }
    }

    func configure(icon: Icon, shadow: Bool = true) {
        self.shadow = shadow
        iconView.image = UIImage(icon: icon)
        iconView.contentMode = .scaleAspectFit
        //iconView.layer.borderColor = UIColor.red.cgColor
        //iconView.layer.borderWidth = 2
        updateColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        outer.frame = bounds
        outer.path = UIBezierPath(ovalIn: outer.bounds).cgPath

        let innerRect = bounds.insetBy(dx: 1, dy: 1)
        inner.frame = innerRect
        inner.path = UIBezierPath(ovalIn: inner.bounds).cgPath

        let iconSize = sqrt(bounds.width * bounds.width / 2) * 0.9
        iconView.frame = CGRect(x: bounds.midX - iconSize / 2,
                                y: bounds.midY - iconSize / 2,
                                width: iconSize,
                                height: iconSize)

        CATransaction.commit()
    }

    private func updateColors() {
        let textPrimary = resolvedColor(Color.textPrimary)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        outer.fillColor = textPrimary.cgColor
        inner.fillColor = resolvedColor(Color.backgroundPrimary).cgColor
        outer.shadowColor = textPrimary.withAlphaComponent(0.5).cgColor
        outer.shadowOpacity = shadow ? 1 : 0
        outer.shadowRadius = 3
        outer.shadowOffset = CGSize(width: -2, height: 2)
        CATransaction.commit()
    }

    private func resolvedColor(_ color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: traitCollection)
    }
}
