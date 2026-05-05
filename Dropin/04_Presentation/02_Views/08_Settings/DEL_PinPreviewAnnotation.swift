#if false
import MapKit
import SwiftUI

// MARK: - Annotation model

final class PinPreviewAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

// MARK: - SwiftUI pin shape

/// Renders the pin in the correct style and size.
struct PinView: View {
    let style: PinStyle
    let size: Double
    var color: Color = .accentColor

    var body: some View {
        let radius = style == .rounded ? size / 2 : 4.0
        let shape  = RoundedRectangle(cornerRadius: radius)
        ZStack {
            shape.fill(color)
            shape.strokeBorder(Color.white, lineWidth: 1.5)
        }
        .frame(width: size, height: size)
    }
}
#endif
