//
//  HostingAnnotationView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import MapKit
import SwiftUI

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
    }

    // MARK: public methods
    func configure(appSettings: AppSettings) {
        pinStyle = appSettings.pinStyle
        pinSize = appSettings.pinSize
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
        
        // Set the size
        let size = hostingController.sizeThatFits(in: UIView.layoutFittingCompressedSize)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        bounds = CGRect(origin: .zero, size: size)
        
        guard let pinSize = pinSize else { fatalError("undefined pinSize") }
        // Set the offset (pin bottom should be centered on coordinate)
        if let _ = annotation as? MKTempPlaceAnnotation {
            // No text below pin
            centerOffset = CGPoint(x: 0, y: -(size.height / 2))
        } else {
            let pinHeight: CGFloat = pinSize
            let bottomHeight = size.height - pinHeight // text + spacing
            let offset: CGFloat = -size.height * 0.5 + bottomHeight
            centerOffset = CGPoint(x: 0, y: offset)
        }
    }
    
    private func configure() {
        guard let _ = annotation else { return }
        guard let pinStyle = pinStyle else { return }
        guard let pinSize = pinSize else { return }

        if let tempPlaceAnnotation = annotation as? MKTempPlaceAnnotation {
            configure(view: PlaceAnnotationView(tempAnnotation: tempPlaceAnnotation,
                                                pinStyle: pinStyle,
                                                pinSize: pinSize))
        } else if let placeAnnotation = annotation as? MKPlaceAnnotation {
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
        guard let placeAnnotation = annotation as? MKPlaceAnnotation else { return }
        let swiftUIView = PlaceAnnotationView(annotation: placeAnnotation,
                                              isSelected: isSelected,
                                              pinStyle: pinStyle,
                                              pinSize: pinSize,
                                              showLabel: showLabel)
        hostingController?.rootView = swiftUIView
    }
}
