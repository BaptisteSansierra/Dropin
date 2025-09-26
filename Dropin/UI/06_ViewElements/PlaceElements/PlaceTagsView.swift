//
//  PlaceTagsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceTagsView: View {

    // MARK: - States & Bindings
    @Binding private var place: Place
    @Binding private var showingTagsSelector: Bool

    // MARK: - private vars
    private var editEnabled: Bool

    // MARK: - Body
    var body: some View {
        Group {
            VStack {
                HStack(alignment: .top) {
                    Text("common.tags")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))

                    if place.tags.count > 0 {
                        FlowLayout(alignment: .leading) {
                            ForEach(place.tags) { tag in
                                TagView(name: tag.name, color: Color(rgba: tag.colorHex))
                            }
                        }
                        .padding([.leading, .trailing, /*.bottom, .top*/])
                    }
                    Spacer()
                    IcoButton(systemImage: "ellipsis", icoSize: 14)
                        .padding(.trailing, 15)
                        .onTapGesture {
                            showingTagsSelector.toggle()
                        }
                        .opacity(editEnabled ? 1 : 0)
                }
            }
            Divider()
                .padding(.horizontal)
        }
    }
    
    // MARK: - init
    init(place: Binding<Place>,
         showingTagsSelector: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingTagsSelector = showingTagsSelector
        self.editEnabled = editEnabled
    }
}

#if DEBUG
#Preview {
    @Previewable @State var place = Place(sdPlace: SDPlace.l1)
    @Previewable @State var showingTagsSelector = true
    PlaceTagsView(place: $place,
                  showingTagsSelector: $showingTagsSelector,
                  editEnabled: true)
}
#endif
