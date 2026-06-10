//
//  TagMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

struct TagMapView: View {
    
    @State private var viewModel: TagMapViewModel

    init(viewModel: TagMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView()
    }
}
