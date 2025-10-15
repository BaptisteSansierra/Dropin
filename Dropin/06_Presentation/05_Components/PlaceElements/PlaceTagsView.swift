//
//  PlaceTagsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceTagsView: View {

    // MARK: - States & Bindings
    @Binding private var place: PlaceUI
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
                            let sortedTags = place.tags.sorted(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
                            ForEach(sortedTags) { tag in
                                TagView(name: tag.name, color: tag.color)
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
    init(place: Binding<PlaceUI>,
         showingTagsSelector: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingTagsSelector = showingTagsSelector
        self.editEnabled = editEnabled
    }
}

#if DEBUG
#Preview {
    @Previewable @State var place = PlaceMapper.toUI(PlaceMapper.toDomain(AppContainer.mockPlaceExample()))
    @Previewable @State var showingTagsSelector = true
    
    PlaceTagsView(place: $place,
                  showingTagsSelector: $showingTagsSelector,
                  editEnabled: true)
}
#endif
