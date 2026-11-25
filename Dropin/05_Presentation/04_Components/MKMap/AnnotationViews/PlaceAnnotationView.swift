//
//  PlaceAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/9/26.
//

import MapKit
import UIKit
import SwiftUI

class PlaceAnnotationView: MKAnnotationView {
    
    private enum LabelStyle {
        case bottom
        case bottom3lines
    }

    // Scale (selectionContainer) and wobble (contentContainer) must live on different layers
    // both are `transform` animations and Core Animation doesn't compose those on a single layer:
    private let selectionContainer = UIView()
    // Holds whichever of the pin style is active
    private let contentContainer = UIView()
    private let pinContentView = PlacePinAnnotationLayerView()
    private let rectContentView = PlaceRectAnnotationLayerView()
    private let label = OutlinedLabel()
    private var titleText: String?
    private var labelStyle: LabelStyle = .bottom3lines
    private let showLabelFeatureEnabled = false

    // Set by `AnnotationViewFactory.createTmpPlaceView` for the pending-place marker shown while creating a new place
    var temporary: Bool = false

    // Settable we can toggle the label depending on external logic
    var showLabel: Bool = true {
        didSet {
            guard showLabelFeatureEnabled else { return }
            guard oldValue != showLabel else { return }
            label.isHidden = !showLabel
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        let wasSelected = isSelected
        super.setSelected(selected, animated: animated)
        guard wasSelected != selected else { return }
        updateSelection(selected: selected, animated: animated)
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        canShowCallout = false
        zPriority = .max   // always draw above a dot sharing the same coordinate

        // Bottom-anchored so the selection scale grows from the pin's tip
        selectionContainer.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        addSubview(selectionContainer)
        // Bottom-anchored too, so the wobble pivots from the pin's tip
        contentContainer.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        selectionContainer.addSubview(contentContainer)
        contentContainer.addSubview(pinContentView)
        contentContainer.addSubview(rectContentView)

        label.textAlignment = .center
        switch labelStyle {
            case .bottom:
                label.numberOfLines = 1
            case .bottom3lines:
                label.numberOfLines = 3
        }
        addSubview(label)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.applyLabelStyle()
        }
    }
    
    func configure(color: UIColor,
                   icon: Icon?,
                   iconExtra: Icon?,
                   pinStyle: PinStyle,
                   size: CGFloat,
                   title: String?,
                   showLabel: Bool) {
        // Measure the label unconditionally so it always renders at its real size/position.
        // Whether that footprint is also folded into `bounds` (so MapKit's collision pass accounts for it) is separate:
        // only when promotion logic is off, since with it on
        // the promoted set is already capped, so we keep the original pin-only bounds.
        titleText = title
        applyLabelStyle()
        let fittedSize: CGSize
        switch labelStyle {
            case .bottom:
                label.sizeToFit()
                fittedSize = label.bounds.size
            case .bottom3lines:
                fittedSize = label.sizeThatFits(CGSize(width: size * 2, height: .greatestFiniteMagnitude))
        }
        label.sizeToFit()
        let hasTitle = !(title ?? "").isEmpty
        let foldLabelIntoBounds = !DropinApp.map.usePinPromotionLogic && hasTitle
        var totalWidth = size
        var totalHeight = size
        var labelFrame = CGRect.zero

        let gap: CGFloat = 4
        let labelSize = hasTitle ? fittedSize : .zero
        if foldLabelIntoBounds {
            totalWidth = max(size, labelSize.width)
            totalHeight = size + gap + labelSize.height
        }
        if hasTitle {
            labelFrame = CGRect(x: totalWidth * 0.5 - labelSize.width * 0.5,
                                y: size + gap,
                                width: labelSize.width,
                                height: labelSize.height)
        }

        UIView.performWithoutAnimation {
            bounds = CGRect(origin: .zero, size: CGSize(width: totalWidth, height: totalHeight))
            // Keep the pin's tip anchored at the true coordinate
            centerOffset = CGPoint(x: 0, y: totalHeight / 2 - size)

            let pinFrame = CGRect(x: (totalWidth - size) / 2, y: 0, width: size, height: size)
            selectionContainer.frame = pinFrame
            contentContainer.frame = selectionContainer.bounds
            pinContentView.frame = contentContainer.bounds
            rectContentView.frame = contentContainer.bounds
            label.frame = labelFrame
        }

        switch pinStyle {
            case .rounded:
                pinContentView.isHidden = false
                rectContentView.isHidden = true
                pinContentView.configure(color: color, icon: icon, iconExtra: iconExtra)
            case .rect:
                pinContentView.isHidden = true
                rectContentView.isHidden = false
                rectContentView.configure(color: color, icon: icon, iconExtra: iconExtra)
        }

        if showLabelFeatureEnabled {
            self.showLabel = showLabel
            label.isHidden = !showLabel
        } else {
            label.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionContainer.transform = .identity
        contentContainer.layer.removeAnimation(forKey: "wobble")
    }

    // MARK: - Label style
    private func applyLabelStyle() {
        label.font = .systemFont(ofSize: 9, weight: .semibold)
        label.textColor = resolvedColor(Color(light: Color(rgba: "#222222"), dark: Color(rgba: "#DDDDDD")))
        label.outlineColor = resolvedColor(Color(light: .white, dark: .black.opacity(0.5)))
        label.outlineWidth = 1
        label.text = titleText
    }

    private func resolvedColor(_ color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: traitCollection)
    }

    // MARK: - Selection
    private func updateSelection(selected: Bool, animated: Bool) {
        let scale: CGFloat = selected ? 1.5 : 1
        let applyScale = { self.selectionContainer.transform = CGAffineTransform(scaleX: scale, y: scale) }

        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0,
                           options: [],
                           animations: applyScale)
        } else {
            applyScale()
        }

        guard selected else { return }
        wobble()
    }

    private func wobble() {
        // `setSelected` can end up invoked more than once for a single logical select
        // don't stack a second wobble on top of one already in flight.
        guard contentContainer.layer.animation(forKey: "wobble") == nil else { return }

        let degrees: [CGFloat] = [0, 10, -8, 5, -3, 0]
        let durations: [Double] = [0.15, 0.15, 0.15, 0.15, 0.1]
        let total = durations.reduce(0, +)

        var keyTimes: [NSNumber] = [0]
        var elapsed: Double = 0
        for duration in durations {
            elapsed += duration
            keyTimes.append(NSNumber(value: elapsed / total))
        }

        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = degrees.map { $0 * .pi / 180 }
        animation.keyTimes = keyTimes
        animation.duration = total
        animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut),
                                          count: degrees.count - 1)
        contentContainer.layer.add(animation, forKey: "wobble")
    }
}
