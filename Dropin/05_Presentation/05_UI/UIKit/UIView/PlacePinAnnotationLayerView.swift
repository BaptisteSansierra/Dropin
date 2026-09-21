//
//  PlacePinAnnotationLayerView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit

/// UIKit port of `PlacePinAnnotationView` (SwiftUI) — `MapPinLayerView` with a
/// `PlaceIconLayerView` badge overlaid at the top right for `iconExtra`.
/// Reusable outside the map, same as the SwiftUI original (see `MockPlacePinAnnotationView`).
///
/// Named `LayerView` for the same reason as `MapPinLayerView` — a class/struct
/// pair can't share a top-level name in the same module.
final class PlacePinAnnotationLayerView: UIView {

    private let pinView = MapPinLayerView()
    private let badge = PlaceIconLayerView()

    private var iconExtra: Icon?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(pinView)
        addSubview(badge)
    }

    func configure(color: UIColor, icon: Icon?, iconExtra: Icon?, shadow: Bool = true) {
        self.iconExtra = iconExtra

        pinView.configure(color: color, icon: icon)

        badge.isHidden = iconExtra == nil
        if let iconExtra {
            badge.configure(icon: iconExtra, shadow: shadow)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        pinView.frame = bounds

        guard iconExtra != nil else { return }

        // Mirrors `PlacePinAnnotationView`'s overlay math: a badge sized
        // `size * 20/36`, anchored to the pin's top-right corner then nudged
        // further out by (size * 7/36, -size * 9/36).
        let size = bounds.width
        let badgeSize = size * 20 / 36
        let center = CGPoint(x: size - badgeSize / 2 + size * 7 / 36,
                             y: badgeSize / 2 - size * 9 / 36)

        badge.frame = CGRect(x: center.x - badgeSize / 2,
                             y: center.y - badgeSize / 2,
                             width: badgeSize,
                             height: badgeSize)
    }
}
