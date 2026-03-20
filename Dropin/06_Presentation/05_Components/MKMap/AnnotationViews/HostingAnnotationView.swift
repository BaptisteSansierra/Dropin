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
    private var pinSize: CGSize {
        switch AnnotationViewFactory.pinMode {
            case .rect:
                return CGSize(width: 36, height: 52)
            case .pin:
                return CGSize(width: 36, height: 52)
        }
    }
    
    // MARK: inits
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        bounds = CGRect(origin: .zero, size: pinSize)
        
        // Set offset once (bottom-center on coordinate)
        switch AnnotationViewFactory.pinMode {
            case .rect:
                centerOffset = CGPoint(x: 0, y: -10)
            case .pin:
                centerOffset = CGPoint(x: 0, y: -10)
        }
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
    
    // MARK: private methods
    /*
    private func getHostingController() -> UIHostingController<PlaceAnnotationView> {
        guard let hostingController = hostingController else {
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.view.backgroundColor = .clear
            self.hostingController = hostingController
            
            addSubview(hostingController.view)
            hostingController.view.frame = CGRect(origin: .zero, size: pinSize)
        }
        return hostingController.rootView = swiftUIView
    }
     */

    private func configure(view: PlaceAnnotationView) {
        if let hostingController = hostingController {
            hostingController.rootView = view
        } else {
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = .clear
            self.hostingController = hostingController
            
            addSubview(hostingController.view)
            hostingController.view.frame = CGRect(origin: .zero, size: pinSize)
        }
    }
    
    private func configure() {
        guard let _ = annotation else { return }
        if let tempPlaceAnnotation = annotation as? MKTempPlaceAnnotation {
            configure(view: PlaceAnnotationView(tempAnnotation: tempPlaceAnnotation))
        } else if let placeAnnotation = annotation as? MKPlaceAnnotation {
            configure(view: PlaceAnnotationView(annotation: placeAnnotation, isSelected: isSelected))
        } else {
            assertionFailure("annotation type not handled '\(type(of: annotation))' : \(annotation)")
        }
    }

    private func updateSelection() {
        guard let placeAnnotation = annotation as? MKPlaceAnnotation else { return }
        let swiftUIView = PlaceAnnotationView(annotation: placeAnnotation, isSelected: isSelected)
        hostingController?.rootView = swiftUIView
    }
}
