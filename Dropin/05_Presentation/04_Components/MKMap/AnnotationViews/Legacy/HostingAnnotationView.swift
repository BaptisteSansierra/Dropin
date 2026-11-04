//
//  HostingAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import MapKit
import SwiftUI

// Disabled - superseded by UIKit annotations as swiftUI hosted annotations are buggy
#if false
class HostingAnnotationView: MKAnnotationView {
    
    // MARK: public properties
    var temporary: Bool = false
    var pinStyle: PinStyle?
    var pinSize: CGFloat?
    var showLabel: Bool = true {
        didSet {
            guard oldValue != showLabel else { return }
            configure()
        }
    }

    // MARK: property overrides
    override var isSelected: Bool {
        didSet {
            updateSelection()
        }
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            configure()
        }
    }

    // MARK: private properties
    private var hostingController: UIHostingController<PlaceAnnotationView>?
    private var lastAppliedPinSize: CGFloat?
    
    // MARK: inits
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: overrides
    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        lastAppliedPinSize = nil
    }

    // MARK: public methods
    func configure(mapSettings: MapSettings) {
        pinStyle = mapSettings.pinStyle
        pinSize = mapSettings.pinSize
        configure()
    }

    // MARK: private methods
    private func configure(view: PlaceAnnotationView) {
        if let hostingController = hostingController {
            hostingController.rootView = view
        } else {
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = .clear
            self.hostingController = hostingController
            
            addSubview(hostingController.view)
        }
        
        guard let hostingController = hostingController else { return }
        guard let pinSize = pinSize else { return }

        // The inner hosting view's frame is purely internal layout (never seen by
        // MapKit) — reassert it unconditionally on every configure so SwiftUI can
        // never silently resize it away from pinSize×pinSize in response to new
        // content (e.g. a different-length label). If it drifted, the *visible*
        // pixels would no longer match this view's actual bounds/frame, which is
        // what MapKit uses for both positioning and touch hit-testing — a pin
        // that looks wrong and can't be tapped where it visually appears.
        UIView.performWithoutAnimation {
            hostingController.view.frame = CGRect(origin: .zero, size: CGSize(square: pinSize))
        }

        // Outer bounds/centerOffset affect this view's position on the map itself,
        // so skip re-touching them when the pin size hasn't actually changed —
        // every such write is a chance to collide with MapKit's own in-flight
        // position animation for this view during a gesture.
        guard pinSize != lastAppliedPinSize else { return }
        lastAppliedPinSize = pinSize

        UIView.performWithoutAnimation {
            bounds       = CGRect(origin: .zero, size: CGSize(square: pinSize))
            // TEMP diagnostic: zeroed out (was `CGPoint(x: 0, y: -(pinSize / 2))`)
            // to test whether the bottom-anchor offset itself is implicated in the
            // decorrelation — with this at .zero the pin anchors at its center,
            // same as the dot. Revert once the theory is confirmed/refuted.
//            centerOffset = .zero

            centerOffset = CGPoint(x: 0, y: -(pinSize / 2))
        }
    }
    
    private func configure() {
        guard let _ = annotation else { return }
        guard let pinStyle = pinStyle else { return }
        guard let pinSize = pinSize else { return }

        if let tempPlaceAnnotation = annotation as? MKDraftPlaceAnnotation {
            configure(view: PlaceAnnotationView(tempAnnotation: tempPlaceAnnotation,
                                                pinStyle: pinStyle,
                                                pinSize: pinSize))
        } else if let placeAnnotation = annotation as? MKPlaceAnnotationRepresentable {
            configure(view: PlaceAnnotationView(annotation: placeAnnotation,
                                                isSelected: isSelected,
                                                pinStyle: pinStyle,
                                                pinSize: pinSize,
                                                showLabel: showLabel))
        } else {
            assertionFailure("annotation type not handled '\(type(of: annotation))' : \(annotation)")
        }
    }

    private func updateSelection() {
        guard let pinStyle = pinStyle else { fatalError("undefined pinStyle") }
        guard let pinSize = pinSize else { fatalError("undefined pinSize") }
        guard let placeAnnotation = annotation as? MKPlaceAnnotationRepresentable else { return }
        let swiftUIView = PlaceAnnotationView(annotation: placeAnnotation,
                                              isSelected: isSelected,
                                              pinStyle: pinStyle,
                                              pinSize: pinSize,
                                              showLabel: showLabel)
        hostingController?.rootView = swiftUIView
    }
}
#endif
