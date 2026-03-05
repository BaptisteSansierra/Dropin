//
//  MKCoordinateSpan+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import MapKit

public extension MKCoordinateSpan {
    
    static var zero: MKCoordinateSpan {
        .init(squareDelta: 0)
    }
    
    init(squareDelta: CGFloat) {
        self.init(latitudeDelta: squareDelta,
                  longitudeDelta: squareDelta)
    }
}
