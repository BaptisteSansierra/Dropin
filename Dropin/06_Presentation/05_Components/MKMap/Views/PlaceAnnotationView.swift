//
//  PlacePinAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

struct PlaceAnnotationView: View {
    
    private struct AnimationValues {
        var rotation: Angle = .zero
    }
    
    // MARK: State & Bindings
    @State private var wobblePulse: Int = 0

    // MARK: private properties
    private let place: PlaceUI?
    private let isSelected: Bool
    
    // MARK: init
    init(annotation: MKPlaceAnnotation, isSelected: Bool) {
        self.place = annotation.place
        self.isSelected = isSelected
    }
    
    init(tempAnnotation: MKTempPlaceAnnotation) {
        self.place = nil
        self.isSelected = false
    }
    
    // MARK: body
    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 0) {

                if let place = place {
                    switch AnnotationViewFactory.pinMode {
                        case .rect:
                            PlaceRectAnnotationView(color: place.groupColor,
                                                    icon: place.group?.icon,
                                                    iconExtra: place.icon,
                                                    size: DropinApp.ui.pinHeight)
                            let rectHeight = PlaceRectAnnotationView.heightFor(size: DropinApp.ui.pinHeight)
                            let arrrowHeight = DropinApp.ui.pinHeight - rectHeight
                            BellCurveShape()
                                .fill(place.groupColor)
                                .frame(width: arrrowHeight * 3.33, height: arrrowHeight)
                        case .pin:
                            MapPinView(color: place.groupColor,
                                       icon: place.group?.icon)
                            .frame(width: DropinApp.ui.pinHeight,
                                   height: DropinApp.ui.pinHeight)
                    }
                } else {
                    switch AnnotationViewFactory.pinMode {
                        case .rect:
                            PlaceRectAnnotationView(size: DropinApp.ui.pinHeight)
                            let rectHeight = PlaceRectAnnotationView.heightFor(size: DropinApp.ui.pinHeight)
                            let arrrowHeight = DropinApp.ui.pinHeight - rectHeight
                            BellCurveShape()
                                .fill(.gray)
                                .frame(width: arrrowHeight * 3.33, height: arrrowHeight)
                        case .pin:
                            MapPinView()
                                .frame(width: DropinApp.ui.pinHeight,
                                       height: DropinApp.ui.pinHeight)
                    }
                }
            }
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
            
            // Outlined title
            if let place = place {
                Text(place.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .outline(color: Color(light: .white, dark: .black.opacity(0.5)),
                             width: 0.5)
                    .overlay {
                        Text(place.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(light: Color(rgba: "#222222"),
                                                   dark: Color(rgba: "#DDDDDD")))
                    }
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isSelected)
        .onChange(of: isSelected) { _, newValue in
            guard newValue else { return }
            wobblePulse += 1 // trigger the rotation animation only on select
        }
        .overlay(content: {
            #if false
            ZStack {
                Rectangle()
                    .fill(.clear)
                    .stroke(.black, style: .init(lineWidth: 1))
                
                GeometryReader { proxy in
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(.black)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                        Spacer()
                    }
                    .onAppear {
                        Log.debug("PIN HEIGHT: \(proxy.size.height)")
                    }
                }
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(.black)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            #endif
        })
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
