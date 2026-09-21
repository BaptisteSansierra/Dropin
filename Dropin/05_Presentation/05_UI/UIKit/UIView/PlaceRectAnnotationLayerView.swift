//
//  PlaceRectAnnotationLayerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit
import SwiftUI

/// UIKit port of `PlaceRectAnnotationView` (SwiftUI) — a nested-ring rounded
/// rect (outer border in `color`, two fainter inset rings) over `backgroundPrimary`,
/// an icon or `PlaceholderPinLayer` fallback, a `PlaceIconLayerView` badge for
/// `iconExtra`, and a `BellCurveLayer` tail below.
///
/// The inner two rings are stroke-only (no fill) rather than each re-filling
/// `backgroundPrimary` like the SwiftUI original's `RoundedRectangle...fill(...)`
/// chain — since they're nested inside the outer ring's already-`backgroundPrimary`
/// fill, an extra fill on top would be visually redundant.
///
/// Named `LayerView` for the same reason as `MapPinLayerView` — a class/struct
/// pair can't share a top-level name in the same module.
final class PlaceRectAnnotationLayerView: UIView {

    private static let borderWidth: CGFloat = 3

    private let outerRing = CAShapeLayer()
    private let midRing = CAShapeLayer()
    private let innerRing = CAShapeLayer()
    private let iconImageView = UIImageView()
    private let placeholderLayer = PlaceholderPinLayer()
    private let badge = PlaceIconLayerView()
    private let bellLayer = BellCurveLayer()

    private var icon: Icon?
    private var iconExtra: Icon?
    private var color: UIColor = .gray

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        outerRing.lineCap = .round
        outerRing.lineJoin = .round
        outerRing.lineWidth = Self.borderWidth
        layer.addSublayer(outerRing)

        midRing.fillColor = UIColor.clear.cgColor
        midRing.lineCap = .round
        midRing.lineJoin = .round
        midRing.lineWidth = Self.borderWidth
        layer.addSublayer(midRing)

        innerRing.fillColor = UIColor.clear.cgColor
        innerRing.lineCap = .round
        innerRing.lineJoin = .round
        innerRing.lineWidth = Self.borderWidth
        layer.addSublayer(innerRing)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label
        addSubview(iconImageView)

        layer.addSublayer(placeholderLayer)

        layer.addSublayer(bellLayer)

        addSubview(badge)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.updateThemeColors()
        }
    }

    func configure(color: UIColor, icon: Icon?, iconExtra: Icon?) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        outerRing.strokeColor = color.cgColor
        midRing.strokeColor = color.withAlphaComponent(0.5).cgColor
        innerRing.strokeColor = color.withAlphaComponent(0.2).cgColor
        bellLayer.fillColor = color.cgColor
        CATransaction.commit()
        updateThemeColors()

        if let icon {
            iconImageView.image = UIImage(icon: icon)
            iconImageView.isHidden = false
            placeholderLayer.isHidden = true
        } else {
            iconImageView.isHidden = true
            placeholderLayer.isHidden = false
        }

        badge.isHidden = iconExtra == nil
        if let iconExtra {
            badge.configure(icon: iconExtra)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = bounds.width
        let borderWidth = Self.borderWidth
        let rectHeight = size * 29 / 36
        let bellHeight = size - rectHeight - 0.5 * borderWidth
        let rectFrame = CGRect(x: 0, y: 0, width: size, height: rectHeight)

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // No inset on any ring's path — SwiftUI's `.stroke()` (unlike
        // `.strokeBorder()`) centers the stroke on the shape's own path, which
        // fills its declared frame corner-to-corner, so the stroke bleeds
        // slightly outside that frame by half the line width. Matching that
        // directly (path == bounds) rather than insetting keeps all three
        // rings consistent with each other and with the original.
        outerRing.frame = rectFrame
        outerRing.path = UIBezierPath(roundedRect: outerRing.bounds, cornerRadius: 5).cgPath

        let midSize = CGSize(width: size * 34 / 36, height: size * 28 / 36)
        let midFrame = CGRect(x: rectFrame.midX - midSize.width / 2,
                              y: rectFrame.midY - midSize.height / 2,
                              width: midSize.width,
                              height: midSize.height)
        midRing.frame = midFrame
        midRing.path = UIBezierPath(roundedRect: midRing.bounds, cornerRadius: 5).cgPath

        let innerSize = CGSize(width: size * 32 / 36, height: size * 26 / 36)
        let innerFrame = CGRect(x: rectFrame.midX - innerSize.width / 2,
                                y: rectFrame.midY - innerSize.height / 2,
                                width: innerSize.width,
                                height: innerSize.height)
        innerRing.frame = innerFrame
        innerRing.path = UIBezierPath(roundedRect: innerRing.bounds, cornerRadius: 5).cgPath

        let contentSize = size * 0.65
        let contentFrame = CGRect(x: rectFrame.midX - contentSize / 2,
                                  y: rectFrame.midY - contentSize / 2,
                                  width: contentSize,
                                  height: contentSize)
        iconImageView.frame = contentFrame
        placeholderLayer.frame = contentFrame
        placeholderLayer.update(in: placeholderLayer.bounds)

        // Mirrors `PlaceRectAnnotationView`'s overlay math: a badge sized
        // `size * 20/36`, anchored to the rect's top-right corner then nudged
        // further out by (size * 12/36, -size * 12/36).
        let badgeSize = size * 20 / 36
        let badgeCenter = CGPoint(x: rectFrame.width - badgeSize / 2 + size * 12 / 36,
                                  y: badgeSize / 2 - size * 12 / 36)
        badge.frame = CGRect(x: badgeCenter.x - badgeSize / 2,
                             y: badgeCenter.y - badgeSize / 2,
                             width: badgeSize,
                             height: badgeSize)

        let bellWidth = bellHeight * 3.33
        let bellFrame = CGRect(x: (size - bellWidth) / 2,
                               y: rectHeight + borderWidth * 0.5,
                               width: bellWidth,
                               height: bellHeight)
        bellLayer.frame = bellFrame
        bellLayer.update(in: bellLayer.bounds)

        CATransaction.commit()
    }

    private func updateThemeColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let backgroundPrimary = resolvedColor(Color.backgroundPrimary)
        outerRing.fillColor = backgroundPrimary.cgColor
        placeholderLayer.fillColor = resolvedColor(Color.textPrimary).cgColor
        CATransaction.commit()
    }

    private func resolvedColor(_ color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: traitCollection)
    }
}
