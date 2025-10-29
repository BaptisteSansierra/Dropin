//
//  ClusterAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/8/25.
//

import SwiftUI
import MapKit
import CoreLocation

/// Draw a rounded bordered rectangle + SFSymbol as annotation
struct ClusterAnnotation: MapContent {
    
    // MARK: - State & Bindables
    @Binding var selectedCluster: MapDisplayClusterItem?
    
    // MARK: - private vars
    private var cluster: MapDisplayClusterItem

    // MARK: - Body
    var body: some MapContent {
        Annotation("", coordinate: cluster.center) {
            
            ClusterAnnotationView(count: cluster.points.count)
                .onTapGesture {
                    selectedCluster = cluster
                }
        }
    }
    
    // MARK: - init
    init(clusterItem: MapDisplayClusterItem, selectedCluster: Binding<MapDisplayClusterItem?>) {
        self.cluster = clusterItem
        self._selectedCluster = selectedCluster
    }
}

struct ClusterAnnotationView: View {

    // MARK: - private vars
    private var color: Color
    private var count: Int

    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 36, height: 36)
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            Text("\(count)")
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - init
    init(count: Int, color: Color = .dropinPrimary) {
        self.count = count
        self.color = color
    }
}

#if DEBUG
struct MockClusterAnnotation: View {
    var mock: MockContainer
    @State var cluster: MapDisplayClusterItem
    @State var selectedCluster: MapDisplayClusterItem? = nil

    var body: some View {
        Map {
            ClusterAnnotation(clusterItem: cluster, selectedCluster: $selectedCluster)
        }
    }
    
    init() {
        self.mock = MockContainer()
        let places = mock.getAllPlaceUI()
        cluster = MapDisplayClusterItem(places: places)
    }
}

#Preview {
    NavigationStack {
        MockClusterAnnotation()
    }
}

#endif
