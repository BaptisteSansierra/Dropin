//
//  DummyTagView.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/25.
//

import SwiftUI
import SwiftData


struct DummyTagView: View {
    
    @Query private var tags: [SDTag]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                Text("\(index) - \(tag.name)")
            }
        }
    }
    
}
