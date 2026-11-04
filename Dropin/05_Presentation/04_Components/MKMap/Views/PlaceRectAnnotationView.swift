//
//  PlaceRectAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

/// Hosts `PlaceRectAnnotationLayerView` (UIKit) the production rect style now enders via the UIKit port.
/// `PlaceRectAnnotationView` is used in views as an annotation preview, *NOT* used in Maps
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

#if DEBUG
/// Legacy SwiftUI implementation
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

struct MockPlaceRectAnnotationView: View {
    var mock: MockContainer
    @State var size: CGFloat = 150
    @State var place1: PlaceUIModel
    @State var place2: PlaceUIModel
    @State var place3: PlaceUIModel
    @State var place4: PlaceUIModel
    @State var place5: PlaceUIModel

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
                    PlaceRectAnnotationView(color: place5.categoryColor,
                                            icon: place5.category?.icon,
                                            iconExtra: place5.icon,
                                            size: size)
                }
                VStack {
                    Text("Legacy").font(.caption)
                    LEGACY_PlaceRectAnnotationView(color: place5.categoryColor,
                                                   icon: place5.category?.icon,
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
            PlaceRectAnnotationView(color: place1.categoryColor,
                                    icon: place1.category?.icon,
                                    iconExtra: place1.icon)
            PlaceRectAnnotationView(color: place2.categoryColor,
                                    icon: place2.category?.icon,
                                    iconExtra: place2.icon)
            PlaceRectAnnotationView(color: place3.categoryColor,
                                    icon: place3.category?.icon,
                                    iconExtra: place3.icon)
            PlaceRectAnnotationView(color: place4.categoryColor,
                                    icon: place4.category?.icon,
                                    iconExtra: place4.icon)
            PlaceRectAnnotationView(color: place5.categoryColor,
                                    icon: place5.category?.icon,
                                    iconExtra: place5.icon)
        }
    }

    init() {
        let mock = MockContainer()
        self.mock = mock
        let group1 = mock.getCategoryUIModel(0)
        let group2 = mock.getCategoryUIModel(1)

        let place = mock.getPlaceUIModel()
        self.place1 = place
        self.place2 = place.copy()
        self.place3 = place.copy()
        self.place4 = place.copy()
        self.place5 = place.copy()

        self.place1.category = nil
        self.place2.category = group1
        self.place3.category = group2
        self.place4.category = nil
        self.place5.category = group2

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
