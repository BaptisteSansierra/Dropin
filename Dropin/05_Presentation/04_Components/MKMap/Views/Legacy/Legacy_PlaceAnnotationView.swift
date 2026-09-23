//
//  PlacePinAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

// Disabled - was only used by `HostingAnnotationView` (also disabled), now
// superseded by UIKit implementation
#if false
struct PlaceAnnotationView: View {
    
    private struct AnimationValues {
        var rotation: Angle = .zero
    }
    
    // MARK: State & Bindings
    @State private var wobblePulse: Int = 0

    // MARK: private properties
    private let place: PlaceUI?
    private let isSelected: Bool
    private let pinStyle: PinStyle
    private let pinSize: CGFloat
    private let showLabel: Bool

    // MARK: init
    init(annotation: any MKPlaceAnnotationRepresentable, isSelected: Bool, pinStyle: PinStyle, pinSize: CGFloat, showLabel: Bool = true) {
        self.place = annotation.place
        self.isSelected = isSelected
        self.pinStyle = pinStyle
        self.pinSize = pinSize
        self.showLabel = showLabel
    }

    init(tempAnnotation: MKDraftPlaceAnnotation, pinStyle: PinStyle, pinSize: CGFloat) {
        self.place = nil
        self.isSelected = false
        self.pinStyle = pinStyle
        self.pinSize = pinSize
        self.showLabel = false
    }
    
    // MARK: body
    var body: some View {
        iconView
            .scaleEffect(CGSize(width: isSelected ? 1.5 : 1,
                                height: isSelected ? 1.5 : 1),
                         anchor: .bottom)
            .rotationEffect(isSelected ? .zero : .zero)  // Trigger for keyframes
            .keyframeAnimator(
                initialValue: AnimationValues(),
                trigger: wobblePulse,
                content: keyframeAnimatorContentGeneric,
                keyframes: { _ in
                    KeyframeTrack(\.rotation) {
                        SpringKeyframe(.degrees(10), duration: 0.15, spring: .smooth)
                        SpringKeyframe(.degrees(-8), duration: 0.15, spring: .smooth)
                        SpringKeyframe(.degrees(5), duration: 0.15, spring: .smooth)
                        SpringKeyframe(.degrees(-3), duration: 0.15, spring: .smooth)
                        SpringKeyframe(.degrees(0), duration: 0.1, spring: .smooth)
                    }})
            // Label as an overlay, not a layout sibling — the icon's own frame
            // (pinSize x pinSize) stays this view's only reported size, so
            // HostingAnnotationView's anchor math never has to account for it.
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: pinSize + 4)
                    if let place = place, showLabel {
                        labelView(name: place.name)
                    }
                }
                .fixedSize()
                .allowsHitTesting(false)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isSelected)
            .onChange(of: isSelected) { _, newValue in
                guard newValue else { return }
                wobblePulse += 1 // trigger the rotation animation only on select
            }
    }

    @ViewBuilder
    private var iconView: some View {
        VStack(spacing: 0) {
            if let place = place {
                switch pinStyle {
                    case .rect:
                        // PlaceRectAnnotationView draws its own arrow internally and its
                        // total height already equals `size` — no external composition needed.
                        PlaceRectAnnotationView(color: place.groupColor,
                                                icon: place.group?.icon,
                                                iconExtra: place.icon,
                                                size: pinSize)
                            .frame(width: pinSize,
                                   height: pinSize)
                    case .rounded:
                        PlacePinAnnotationView(color: place.groupColor,
                                               icon: place.group?.icon,
                                               iconExtra: place.icon,
                                               size: pinSize)
                            .frame(width: pinSize,
                                   height: pinSize)
                }
            } else {
                switch pinStyle {
                    case .rect:
                        PlaceRectAnnotationView(size: pinSize)
                            .frame(width: pinSize,
                                   height: pinSize)
                    case .rounded:
                        MapPinView()
                            .frame(width: pinSize,
                                   height: pinSize)
                }
            }
        }
    }

    @ViewBuilder
    private func labelView(name: String) -> some View {
        Text(name)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .outline(color: Color(light: .white, dark: .black.opacity(0.5)),
                     width: 0.5)
            .overlay {
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(light: Color(rgba: "#222222"),
                                           dark: Color(rgba: "#DDDDDD")))
            }
            .lineLimit(1)
            .fixedSize()
    }
    
    /*
     nonisolated public func keyframeAnimator<Value>(initialValue: Value, trigger: some Equatable,
     @ViewBuilder content: @escaping @Sendable (PlaceholderContentView<Self>, Value) -> some View,
     
     @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes) -> some View
     */

    nonisolated private func keyframeAnimatorContentGeneric(content: PlaceholderContentView<some View>, value: AnimationValues) -> some View {
        content
            .rotationEffect(value.rotation)
    }
    
    /*
    @KeyframesBuilder<AnimationValues>
    private func keyframeAnimatorKeyframes(value: AnimationValues) -> some View {
        KeyframeTrack(\.rotation) {
            SpringKeyframe(.degrees(10), duration: 0.15, spring: .smooth)
            SpringKeyframe(.degrees(-8), duration: 0.15, spring: .smooth)
            SpringKeyframe(.degrees(5), duration: 0.15, spring: .smooth)
            SpringKeyframe(.degrees(-3), duration: 0.15, spring: .smooth)
            SpringKeyframe(.degrees(0), duration: 0.1, spring: .smooth)
        }
    }
     */
}


#if DEBUG
struct MockPlaceAnnotationView: View {
    var mock: MockContainer
    var pinStyle = PinStyle.rounded
    var pinSize: CGFloat = 36
    @State var size: CGFloat = 150
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var place4: PlaceUI
    @State var place5: PlaceUI

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 50) {
                PlaceAnnotationView(annotation: MKPlaceDotAnnotation(place: place1),
                                    isSelected: false,
                                    pinStyle: pinStyle,
                                    pinSize: pinSize)
                PlaceAnnotationView(annotation: MKPlaceDotAnnotation(place: place2),
                                    isSelected: false,
                                    pinStyle: pinStyle,
                                    pinSize: pinSize)
            }
            .padding(.bottom, 50)
            HStack(spacing: 50) {
                PlaceAnnotationView(annotation: MKPlaceDotAnnotation(place: place3),
                                    isSelected: false,
                                    pinStyle: pinStyle,
                                    pinSize: pinSize)
                PlaceAnnotationView(annotation: MKPlaceDotAnnotation(place: place4),
                                    isSelected: false,
                                    pinStyle: pinStyle,
                                    pinSize: pinSize)
            }
            .padding(.bottom, 50)

            ZStack {
                RoundedRectangle(cornerSize: 10)
                    .fill(.gray)
                    .frame(width: 120, height: 120)
                PlaceAnnotationView(annotation: MKPlaceDotAnnotation(place: place5),
                                    isSelected: true,
                                    pinStyle: pinStyle,
                                    pinSize: pinSize)
                Text(verbatim: "SELECTED")
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.top, 90)
            }
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        let places = mock.getAllPlaceUI()
        self.place1 = places[0]
        self.place2 = places[1]
        self.place3 = places[2]
        self.place4 = places[3]
        self.place5 = places[4]

        self.place2.icon = .sf("duffle.bag")
        self.place3.icon = nil
        self.place4.icon = .sf("figure.seated.side.left.airbag.on")
        self.place5.icon = .sf("ivfluid.bag")
    }
}

#Preview {
    MockPlaceAnnotationView()
}
#endif
#endif

