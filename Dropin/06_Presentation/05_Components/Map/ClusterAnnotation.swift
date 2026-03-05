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
    @Binding var selectedClusterId: UUID?
    
    // MARK: - private vars
    private var cluster: ClusterAnnotationModel

    // MARK: - Body
    var body: some MapContent {
        Annotation("", coordinate: cluster.coordinate) {
            ClusterAnnotationView(count: cluster.count)
                .onTapGesture {
                    selectedClusterId = cluster.id
                }
        }
    }
    
    // MARK: - init
    init(cluster: ClusterAnnotationModel,
         selectedClusterId: Binding<UUID?>) {
        self.cluster = cluster
        self._selectedClusterId = selectedClusterId
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
                .fill(.backgroundPrimary)
                .frame(width: 36, height: 36)
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            Text("\(count)")
                .font(.body)
                .foregroundStyle(.backgroundPrimary)
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
    @State var cluster: ClusterAnnotationModel
    @State var selectedClusterId: UUID? = nil

    var body: some View {
        Map(initialPosition: .region(.london)) {
            ClusterAnnotation(cluster: cluster,
                              selectedClusterId: $selectedClusterId)
        }
    }
    
    init() {
        self.mock = MockContainer()
        cluster = ClusterAnnotationModel(coordinate: .london, count: 5, span: .zero)
    }
}

#Preview {
    NavigationStack {
        MockClusterAnnotation()
    }
}

#endif
