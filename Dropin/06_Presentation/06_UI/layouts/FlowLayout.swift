//
//  FlowLayout.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct FlowLayout: Layout {
    
    // MARK: - private vars
    private var alignment: HorizontalAlignment
    private var spacingV: CGFloat
    private var spacingH: CGFloat

    // MARK: - init
    init(alignment: HorizontalAlignment = .center, spacingV: CGFloat = 10, spacingH: CGFloat = 10) {
        self.alignment = alignment
        self.spacingV = spacingV
        self.spacingH = spacingH
    }
    
    // MARK: - Layout methods
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        let rows = generateRow(maxWidth: maxWidth, proposal: proposal, subviews: subviews)
        for (index, row) in rows.enumerated() {
            height += row.maxHeight(proposal)
            if index != rows.count - 1 {
                height += spacingV
            }
        }
        return .init(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var yPos: CGFloat = bounds.minY
        let rows = generateRow(maxWidth: bounds.width, proposal: proposal, subviews: subviews)
        var i = 0
        for row in rows {
            var xPos: CGFloat = 0
            switch alignment {
                case .leading:
                    xPos = bounds.minX
                case .trailing:
                    let rowWidth = row.contentWidth(proposal, spacing: spacingH)
                    xPos = bounds.minX + bounds.width - rowWidth
                case .center:
                    let rowWidth = row.contentWidth(proposal, spacing: spacingH)
                    xPos = bounds.midX - rowWidth * 0.5
                default:
                    print("alignment type \(alignment) not handled in FlowLayout, use leading")
                    xPos = bounds.minX
            }
            for view in row {
                view.place(at: CGPoint(x: xPos, y: yPos), proposal: proposal)
                xPos += view.sizeThatFits(proposal).width + spacingH
            }
            xPos = bounds.minX
            yPos += row.maxHeight(proposal) + spacingV
            i += 1
        }
    }
    
    // MARK: - private
    private func generateRow(maxWidth: CGFloat, proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var row: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        var posX: CGFloat = 0
        for view in subviews {
            let viewSize = view.sizeThatFits(proposal)
            if posX + viewSize.width + spacingH > maxWidth {
                rows.append(row)
                row.removeAll()
                // Reset posx
                posX = 0
                row.append(view)
                // Increment posx
                posX += viewSize.width + spacingH
            } else {
                row.append(view)
                // Increment posx
                posX += viewSize.width + spacingH
            }
        }
        if !row.isEmpty {
            rows.append(row)
        }
        return rows
    }
}

extension [LayoutSubviews.Element] {
    
    func maxHeight(_ proposal: ProposedViewSize) -> CGFloat {
        self.compactMap { view in
            view.sizeThatFits(proposal).height
        }.max() ?? 0
    }
    
    func contentWidth(_ proposal: ProposedViewSize, spacing: CGFloat) -> CGFloat {
        let sum = self.reduce(0) { partialResult, view in
            partialResult + view.sizeThatFits(proposal).width + spacing
        }
        // remove the last spacing
        return sum - spacing
    }
}

#if DEBUG

struct FlowLayoutPreviewView: View {
    
    private var count = 40
    private var sizes: [CGFloat] = [CGFloat]()

    var body: some View {
        FlowLayout(alignment: .trailing, spacingV: 40, spacingH: 4) {
            ForEach(Array(sizes.enumerated()), id: \.offset) { index, element in
                Text("_NOTTR_num \(index)")
                    .frame(width: element, height: 25)
                    .overlay {
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(.red, lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, 5)
    }
    
    init() {
        for _ in 0..<count {
            sizes.append(CGFloat(Int.random(in: 20...120)))
        }
    }
}

#Preview {
    FlowLayoutPreviewView()
}

#endif
