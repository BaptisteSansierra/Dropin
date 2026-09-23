//
//  PlacePinAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

/// Hosts `PlacePinAnnotationLayerView` (UIKit) — the production pin style now
/// renders via the UIKit port. `LEGACY_PlacePinAnnotationView` below is the
/// original SwiftUI implementation, kept (unused in production) for
/// side-by-side comparison in `MockPlacePinAnnotationView`'s preview.
struct PlacePinAnnotationView: View {

    private var color: Color
    private var icon: Icon?
    private var iconExtra: Icon?
    private var size: CGFloat
    private var shadow: Bool

    init(color: Color = .dropinPrimary,
         icon: Icon? = nil,
         iconExtra: Icon? = nil,
         size: CGFloat = 36,
         shadow: Bool = true) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra
        self.size = size
        self.shadow = shadow
    }

    var body: some View {
        PlacePinAnnotationLayerViewRepresentable(color: UIColor(color),
                                                  icon: icon,
                                                  iconExtra: iconExtra,
                                                  shadow: shadow)
            .frame(width: size, height: size)
    }
}

private struct PlacePinAnnotationLayerViewRepresentable: UIViewRepresentable {
    var color: UIColor
    var icon: Icon?
    var iconExtra: Icon?
    var shadow: Bool

    func makeUIView(context: Context) -> PlacePinAnnotationLayerView {
        PlacePinAnnotationLayerView()
    }

    func updateUIView(_ uiView: PlacePinAnnotationLayerView, context: Context) {
        uiView.configure(color: color, icon: icon, iconExtra: iconExtra, shadow: shadow)
    }
}

/// Original SwiftUI implementation — not used in production anymore, kept for
/// comparison against the UIKit-hosted `PlacePinAnnotationView` above.
struct LEGACY_PlacePinAnnotationView: View {

    // MARK: - private vars
    private var color: Color
    private var icon: Icon?
    private var iconExtra: Icon?
    private var size: CGFloat
    private var shadow: Bool

    // MARK: - init
    init(color: Color = .dropinPrimary,
         icon: Icon? = nil,
         iconExtra: Icon? = nil,
         size: CGFloat = 36,
         shadow: Bool = true) {
        self.color = color
        self.icon = icon
        self.iconExtra = iconExtra
        self.size = size
        self.shadow = shadow
    }

    // MARK: - Body
    var body: some View {
        MapPinView(color: color,
                   icon: icon,
                   shadow: shadow)
            .frame(width: size, height: size)
            .overlay(content: {
                if let iconExtra = iconExtra {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Spacer()
                            PlaceIconView(icon: iconExtra, size: size * 20 / 36)
                        }
                        Spacer()
                    }
                    .offset(x: size * 7 / 36,
                            y: size * -9 / 36)
                }
            })
    }
}

#if DEBUG
struct MockPlacePinAnnotationView: View {
    var mock: MockContainer
    @State var size: CGFloat = 150
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var place4: PlaceUI
    @State var place5: PlaceUI
    @State var place6: PlaceUI

    var body: some View {
        VStack {
            HStack(spacing: 50) {
                contentView.environment(\.colorScheme, .light)
                contentView.environment(\.colorScheme, .dark)
            }
            .padding(.bottom, 50)
            Divider()
                .padding(.bottom, 50)

            // UIKit vs Legacy SwiftUI side by side, at the
            // slider-controlled size, for direct comparison.
            HStack(spacing: 30) {
                VStack {
                    Text("New").font(.caption)
                    PlacePinAnnotationView(color: place5.groupColor,
                                           icon: place5.group?.icon,
                                           iconExtra: place5.icon,
                                           size: size)
                }
                VStack {
                    Text("Legacy").font(.caption)
                    LEGACY_PlacePinAnnotationView(color: place5.groupColor,
                                                  icon: place5.group?.icon,
                                                  iconExtra: place5.icon,
                                                  size: size)
                }
            }
            HStack(spacing: 30) {
                VStack {
                    PlacePinAnnotationView(color: place6.groupColor,
                                           icon: place6.group?.icon,
                                           iconExtra: place6.icon,
                                           size: size)
                }
                VStack {
                    LEGACY_PlacePinAnnotationView(color: place6.groupColor,
                                                  icon: place6.group?.icon,
                                                  iconExtra: place6.icon,
                                                  size: size)
                }
            }
//            .frame(height: 220)

            Slider(value: $size, in: 10...200)
                .padding(.horizontal, 30)

            Divider()
        }
//        .onChange(of: size) { oldValue, newValue in
//            print("newValue:\(newValue)")
//        }
    }

    var contentView: some View {
        VStack(spacing: 30) {
            HStack(spacing: 10) {
                PlacePinAnnotationView(color: place1.groupColor,
                                       icon: place1.group?.icon,
                                       iconExtra: place1.icon,
                                       size: 50)
                PlacePinAnnotationView(color: place2.groupColor,
                                       icon: place2.group?.icon,
                                       iconExtra: place2.icon,
                                       size: 50)
            }

            HStack(spacing: 10) {
                PlacePinAnnotationView(color: place3.groupColor,
                                       icon: place3.group?.icon,
                                       iconExtra: place3.icon,
                                       size: 50)
                PlacePinAnnotationView(color: place4.groupColor,
                                       icon: place4.group?.icon,
                                       iconExtra: place4.icon,
                                       size: 50)
            }
        }
    }

    init() {
        let mock = MockContainer()
        self.mock = mock
        let group1 = mock.getGroupUI(0)  // FA Symbol
        group1.icon = Icon.fa("spa")
        let group2 = mock.getGroupUI(1)  // SF Symbol
        //group2.icon = Icon.fa("pizza-slice")

        let place = mock.getPlaceUI()
        self.place1 = place
        self.place2 = place.copy()
        self.place3 = place.copy()
        self.place4 = place.copy()
        self.place5 = place.copy()
        self.place6 = place.copy()

        self.place1.group = nil
        self.place2.group = group1
        self.place3.group = group2
        self.place4.group = nil
        self.place5.group = group2
        self.place6.group = group1

        self.place2.icon = .sf("duffle.bag")
        self.place3.icon = nil
        self.place4.icon = .sf("figure.seated.side.left.airbag.on")
        self.place5.icon = .sf("ivfluid.bag")
        self.place6.icon = .fa("paw")
    }
}

#Preview {
    MockPlacePinAnnotationView()
}
#endif
