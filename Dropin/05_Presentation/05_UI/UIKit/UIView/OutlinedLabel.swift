//
//  OutlinedLabel.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit

final class OutlinedLabel: UIView {

    var text: String? {
        didSet { syncText() }
    }

    var font: UIFont = .systemFont(ofSize: 17) {
        didSet { syncFont() }
    }

    var textColor: UIColor = .label {
        didSet { label.textColor = textColor }
    }

    var outlineColor: UIColor = .white {
        didSet { outlineLabels.forEach { $0.textColor = outlineColor } }
    }

    var outlineWidth: CGFloat = 1 {
        didSet { setNeedsLayout() }
    }

    var textAlignment: NSTextAlignment = .center {
        didSet { syncAlignment() }
    }

    private let label = UILabel()
    // Added before `label` so the real, filled text draws on top of them.
    private let outlineLabels: [UILabel] = (0..<8).map { _ in UILabel() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        outlineLabels.forEach { outlineLabel in
            outlineLabel.numberOfLines = 1
            outlineLabel.isAccessibilityElement = false
            addSubview(outlineLabel)
        }
        label.numberOfLines = 1
        addSubview(label)
        syncFont()
        syncAlignment()
    }

    override var intrinsicContentSize: CGSize {
        label.intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        label.sizeThatFits(size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = bounds
        for (outlineLabel, offset) in zip(outlineLabels, Self.offsets(width: outlineWidth)) {
            outlineLabel.frame = bounds.offsetBy(dx: offset.x, dy: offset.y)
        }
    }

    private static func offsets(width: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: -width, y: -width), CGPoint(x: width, y: -width),
            CGPoint(x: -width, y: width),  CGPoint(x: width, y: width),
            CGPoint(x: 0, y: -width),      CGPoint(x: 0, y: width),
            CGPoint(x: -width, y: 0),      CGPoint(x: width, y: 0)
        ]
    }

    private func syncText() {
        label.text = text
        outlineLabels.forEach { $0.text = text }
        invalidateIntrinsicContentSize()
    }

    private func syncFont() {
        label.font = font
        outlineLabels.forEach { $0.font = font }
        invalidateIntrinsicContentSize()
    }

    private func syncAlignment() {
        label.textAlignment = textAlignment
        outlineLabels.forEach { $0.textAlignment = textAlignment }
    }
}
