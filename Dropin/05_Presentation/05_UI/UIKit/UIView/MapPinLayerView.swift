//
//  MapPinLayerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit
import SwiftUI

/// UIKit port of `MapPinView` (SwiftUI) — composes `MapPinLayer` (the balloon-pin
/// outline), a gradient circle for the place color, and either an icon or
/// `PlaceholderPinLayer` as fallback. Named `LayerView` rather than `MapPinView`
/// since a class/struct pair can't share a top-level name in the same module.
///
/// Color math (lighten/darken/luminance) is reused from the existing `Color`
/// extensions via a `UIColor` <-> `Color` bridge rather than re-derived here,
/// to avoid duplicating that logic.
final class MapPinLayerView: UIView {

    private let pinLayer = MapPinLayer()
    private let gradientLayer = CAGradientLayer()
    private let gradientMask = CAShapeLayer()
    private let iconImageView = UIImageView()
    private let placeholderLayer = PlaceholderPinLayer()

    private var icon: Icon?

    private var shapeColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(Color(rgba: "#222222")) : .white
        }.resolvedColor(with: traitCollection)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        pinLayer.shadowColor = UIColor.black.cgColor
        pinLayer.shadowOpacity = 0.3
        pinLayer.shadowRadius = 5
        pinLayer.shadowOffset = .zero
        layer.addSublayer(pinLayer)

        gradientLayer.mask = gradientMask
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)

        iconImageView.contentMode = .scaleAspectFit
        //iconImageView.layer.borderColor = UIColor.red.cgColor
        //iconImageView.layer.borderWidth = 1
        addSubview(iconImageView)

        layer.addSublayer(placeholderLayer)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateShapeColor()
        }
    }

    private func updateShapeColor() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pinLayer.fillColor = shapeColor.cgColor
        CATransaction.commit()
    }

    func configure(color: UIColor, icon: Icon?) {
        self.icon = icon

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pinLayer.fillColor = shapeColor.cgColor
        gradientLayer.colors = gradientColors(for: color)
        iconImageView.tintColor = iconColor(for: color)
        placeholderLayer.fillColor = iconColor(for: color).cgColor
        setNeedsLayout()
        CATransaction.commit()

        if let icon {
            iconImageView.image = UIImage(icon: icon)
            iconImageView.isHidden = false
            placeholderLayer.isHidden = true
        } else {
            iconImageView.isHidden = true
            placeholderLayer.isHidden = false
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        pinLayer.frame = bounds
        pinLayer.update(in: bounds)

        let contentRadius = MapPinLayer.radius(in: bounds) * 0.85
        let center = MapPinLayer.center(in: bounds)
        let contentDiameter = contentRadius * 2
        let contentFrame = CGRect(x: center.x - contentRadius,
                                  y: center.y - contentRadius,
                                  width: contentDiameter,
                                  height: contentDiameter)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = contentFrame
        gradientMask.frame = gradientLayer.bounds
        gradientMask.path = UIBezierPath(ovalIn: gradientLayer.bounds).cgPath

        let fontSize = sqrt(contentDiameter * contentDiameter / 2) * 0.8
        iconImageView.frame = CGRect(x: center.x - fontSize / 2,
                                     y: center.y - fontSize / 2,
                                     width: fontSize,
                                     height: fontSize)

        let placeholderSide = contentRadius * 1.3
        placeholderLayer.frame = CGRect(x: center.x - placeholderSide / 2,
                                        y: center.y - placeholderSide / 2,
                                        width: placeholderSide,
                                        height: placeholderSide)
        placeholderLayer.update(in: placeholderLayer.bounds)
        CATransaction.commit()
    }

    private func gradientColors(for color: UIColor) -> [CGColor] {
        let swiftColor = Color(color)
        var colors = [swiftColor, swiftColor.darken(factor: 0.3)]
        if swiftColor.luminance() < 0.25 {
            colors = [swiftColor, swiftColor.lighten(factor: 0.3)]
        }
        return colors.map { UIColor($0).cgColor }
    }

    private func iconColor(for color: UIColor) -> UIColor {
        Color(color).luminance() > 0.7 ? UIColor(Color(rgba: "444444")) : .white
    }
}
