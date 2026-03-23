//
//  PlacePinAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

struct PlacePinAnnotationView: View {

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

    var body: some View {
        VStack {
            HStack(spacing: 50) {
                contentView.environment(\.colorScheme, .light)
                contentView.environment(\.colorScheme, .dark)
            }
            .padding(.bottom, 50)
            Divider()
                .padding(.bottom, 50)
            HStack {
                PlacePinAnnotationView(color: place5.groupColor,
                                       icon: place5.group?.icon,
                                       iconExtra: place5.icon,
                                       size: size)
            }
            .frame(height: 200)
            
            Slider(value: $size, in: 10...200)
                .padding(.horizontal, 30)
            
            Divider()
        }
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
    MockPlacePinAnnotationView()
}
#endif

