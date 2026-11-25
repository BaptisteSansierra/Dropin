//
//  DropinLoader.swift
//  Dropin
//
//  Created by baptiste sansierra on 21/5/26.
//

import SwiftUI

/// Generic loader component.
/// - `overlay` style: card with material background + shadow, suited to float over content
/// - `inline` style: just spinner (and optional caption), no card
struct DropinLoader: View {

    enum Style {
        case overlay
        case inline
    }

    enum Size {
        case small
        case regular

        var scale: CGFloat {
            switch self {
                case .small:    return 0.8
                case .regular:  return 1.0
            }
        }

        var cardSide: CGFloat {
            switch self {
                case .small:    return 70
                case .regular:  return 90
            }
        }
    }

    let style: Style
    let size: Size
    let caption: LocalizedStringKey?

    init(style: Style = .overlay,
         size: Size = .regular,
         caption: LocalizedStringKey? = nil) {
        self.style = style
        self.size = size
        self.caption = caption
    }

    var body: some View {
        switch style {
            case .overlay:
                overlayBody
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            case .inline:
                inlineBody
                    .transition(.opacity)
        }
    }

    private var overlayBody: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(size == .small ? .regular : .large)
                .tint(.dropinPrimary)
            if let caption {
                Text(caption)
                    .textStyle(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minWidth: size.cardSide, minHeight: size.cardSide)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var inlineBody: some View {
        VStack(spacing: 6) {
            ProgressView()
                .controlSize(size == .small ? .small : .regular)
                .tint(.dropinPrimary)
            if let caption {
                Text(caption)
                    .textStyle(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#if DEBUG
#Preview("Overlay") {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        VStack(spacing: 30) {
            DropinLoader()
            DropinLoader(caption: "Looking up…")
            DropinLoader(size: .small, caption: "Loading")
        }
    }
}

#Preview("Inline") {
    VStack(spacing: 30) {
        DropinLoader(style: .inline)
        DropinLoader(style: .inline, caption: "Looking up…")
        DropinLoader(style: .inline, size: .small, caption: "Loading")
    }
    .padding()
}
#endif
