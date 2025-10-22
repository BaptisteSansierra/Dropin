//
//  PlaceNotesView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceNotesView: View {
    
    // MARK: - States & Bindings
    @Binding private var notes: String
    @Binding private var showNotesField: Bool
    @Binding private var scrollPosition: ScrollPosition
    
    // MARK: - private vars
    private var editEnabled: Bool

    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text("common.notes")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                Spacer()
            }
            TextField("placeholder.notes", text: $notes, axis: .vertical)
                .lineLimit(2...6)
                .padding(.horizontal)
                .onChange(of: notes) { oldVal, newVal in
                    // Scroll to bottom so edited line do not disapear under scroll
                    withAnimation {
                        scrollPosition.scrollTo(edge: .bottom)
                    }
                }
                .disabled(!editEnabled)
        }
        .opacity(showNotesField ? 1 : 0)
        .tag("notes")
    }
    
    // MARK: - init
    init(notes: Binding<String>,
         showNotesField: Binding<Bool>,
         scrollPosition: Binding<ScrollPosition>,
         editEnabled: Bool) {
        self._notes = notes
        self._showNotesField = showNotesField
        self._scrollPosition = scrollPosition
        self.editEnabled = editEnabled
    }
}
