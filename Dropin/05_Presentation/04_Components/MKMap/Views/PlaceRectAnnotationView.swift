//
//  PlaceRectAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

/// Hosts `PlaceRectAnnotationLayerView` (UIKit) — the production rect style now
/// renders via the UIKit port. `LEGACY_PlaceRectAnnotationView` below is the
/// original SwiftUI implementation, kept (unused in production) for
/// side-by-side comparison in `MockPlaceRectAnnotationView`'s preview.
struct PlaceRectAnnotationView: View {

    private var color: Color
    private var icon: Icon?
    private var iconExtra: Icon?
    private var size: CGFloat

    init(color: Color = .dropinPrimary,
         icon: Icon? = nil,
         iconExtra: Icon? = nil,
         size: CGFloat = 36) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra
        self.size = size
    }

    var body: some View {
        PlaceRectAnnotationLayerViewRepresentable(color: UIColor(color),
                                                   icon: icon,
                                                   iconExtra: iconExtra)
            .frame(width: size, height: size)
    }
}

private struct PlaceRectAnnotationLayerViewRepresentable: UIViewRepresentable {
    var color: UIColor
    var icon: Icon?
    var iconExtra: Icon?

    func makeUIView(context: Context) -> PlaceRectAnnotationLayerView {
        PlaceRectAnnotationLayerView()
    }

    func updateUIView(_ uiView: PlaceRectAnnotationLayerView, context: Context) {
        uiView.configure(color: color, icon: icon, iconExtra: iconExtra)
    }
}

/// Original SwiftUI implementation — not used in production anymore, kept for
/// comparison against the UIKit-hosted `PlaceRectAnnotationView` above.
struct LEGACY_PlaceRectAnnotationView: View {

//    static func heightFor(width: CGFloat) -> CGFloat {
//        return width * 30 / 36
//    }

    private let borderWidth: CGFloat = 4
    private var rectHeight: CGFloat {
        size * 29 / 36
    }
    private var bellHeight: CGFloat {
        size - rectHeight - 0.5 * borderWidth
    }

    // MARK: - private vars
    private var color: Color
    private var icon: Icon?
    private var iconExtra: Icon?
    private var size: CGFloat

    // MARK: - init
    init(color: Color = .dropinPrimary,
         icon: Icon? = nil,
         iconExtra: Icon? = nil,
         size: CGFloat = 36) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra
        self.size = size
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: borderWidth * 0.5) {
            ZStack {
                RoundedRectangle(cornerSize: 5)
                    .stroke(color,
                    //.stroke(.red,
                            style: StrokeStyle(lineWidth: borderWidth,
                                               lineCap: .round,
                                               lineJoin: .round))
                    .fill(.backgroundPrimary)
                    .frame(width: size,
                           height: rectHeight)
                RoundedRectangle(cornerSize: 5)
                    .stroke(color.opacity(0.5),
                    //.stroke(.green.opacity(0.0),
                            style: StrokeStyle(lineWidth: borderWidth,
                                               lineCap: .round,
                                               lineJoin: .round))
                    .fill(.backgroundPrimary)
                    .frame(width: size * 34 / 36, height: size * 28 / 36)
                RoundedRectangle(cornerSize: 5)
                    .stroke(color.opacity(0.2),
                    //.stroke(.blue.opacity(0.0),
                            style: StrokeStyle(lineWidth: borderWidth,
                                               lineCap: .round,
                                               lineJoin: .round))
                    .fill(.backgroundPrimary)
                    .frame(width: size * 32 / 36, height: size * 26 / 36)
                if let icon = icon {
                    IconView(icon: icon)
                        .size(size * 18 / 36)
                } else {
                    PlaceholderPinShape()
                        .frame(width: size * 18 / 36,
                               height: size * 18 / 36)
                        .foregroundStyle(.textPrimary)
                }
            }
            .overlay(content: {
                if let iconExtra = iconExtra {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Spacer()
                            PlaceIconView(icon: iconExtra, size: size * 20 / 36)
                        }
                        Spacer()
                    }
                    .offset(x: size * 12 / 36, y: size * -12 / 36)
                }
            })

            BellCurveShape()
                .fill(color)
                .frame(width: bellHeight * 3.33, height: bellHeight)
        }
    }
}

#if DEBUG
struct MockPlaceRectAnnotationView: View {
    var mock: MockContainer
    @State var size: CGFloat = 150
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var place4: PlaceUI
    @State var place5: PlaceUI

    var body: some View {
        VStack {
            HStack(spacing: 50) {
                contentView.environment(\.colorScheme, .light)
                contentView.environment(\.colorScheme, .dark)
            }
            .padding(.bottom, 50)
            Divider()
                .padding(.bottom, 50)

            // New (UIKit-hosted) vs Legacy (SwiftUI) side by side, at the
            // slider-controlled size, for direct comparison.
            HStack(spacing: 30) {
                VStack {
                    Text("New").font(.caption)
                    PlaceRectAnnotationView(color: place5.groupColor,
                                            icon: place5.group?.icon,
                                            iconExtra: place5.icon,
                                            size: size)
                }
                VStack {
                    Text("Legacy").font(.caption)
                    LEGACY_PlaceRectAnnotationView(color: place5.groupColor,
                                                   icon: place5.group?.icon,
                                                   iconExtra: place5.icon,
                                                   size: size)
                }
            }
            .frame(height: 220)

            Slider(value: $size, in: 10...200)
                .padding(.horizontal, 30)

            Divider()
        }
    }

    var contentView: some View {
        VStack(spacing: 30) {
            PlaceRectAnnotationView(color: place1.groupColor,
                                    icon: place1.group?.icon,
                                    iconExtra: place1.icon)
            PlaceRectAnnotationView(color: place2.groupColor,
                                    icon: place2.group?.icon,
                                    iconExtra: place2.icon)
            PlaceRectAnnotationView(color: place3.groupColor,
                                    icon: place3.group?.icon,
                                    iconExtra: place3.icon)
            PlaceRectAnnotationView(color: place4.groupColor,
                                    icon: place4.group?.icon,
                                    iconExtra: place4.icon)
            PlaceRectAnnotationView(color: place5.groupColor,
                                    icon: place5.group?.icon,
                                    iconExtra: place5.icon)
        }
    }

    init() {
        let mock = MockContainer()
        self.mock = mock
        let group1 = mock.getGroupUI(0)
        let group2 = mock.getGroupUI(1)

        let place = mock.getPlaceUI()
        self.place1 = place
        self.place2 = place.copy()
        self.place3 = place.copy()
        self.place4 = place.copy()
        self.place5 = place.copy()

        self.place1.group = nil
        self.place2.group = group1
        self.place3.group = group2
        self.place4.group = nil
        self.place5.group = group2

        self.place2.icon = .sf("duffle.bag")
        self.place3.icon = nil
        self.place4.icon = .sf("figure.seated.side.left.airbag.on")
        self.place5.icon = .sf("ivfluid.bag")
    }
}

#Preview {
    MockPlaceRectAnnotationView()
}
#endif
