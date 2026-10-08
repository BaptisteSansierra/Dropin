//
//  MapItemDetailView.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/10/26.
//

// TODO: remove file

#if false
import SwiftUI
import MapKit

struct MapItemDetailView: UIViewControllerRepresentable {
    let mapItem: MKMapItem
    
    func makeUIViewController(context: Context) -> MKMapItemDetailViewController {
        let vc = MKMapItemDetailViewController()
        vc.mapItem = mapItem
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MKMapItemDetailViewController, context: Context) {
    }
}

struct MapItemDetailPlusView: View {
    let mapItem: MKMapItem
    let onCreate: (MKMapItem) -> Void

    var body: some View {
        VStack {
            MapItemDetailView(mapItem: mapItem)
            MainButton(text: "common.create_place", systemImage: "plus") {
                onCreate(mapItem)
            }
            .padding(.horizontal)
        }
    }
}
#endif
