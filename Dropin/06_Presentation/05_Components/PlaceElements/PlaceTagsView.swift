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

    // MARK: - init
    init(place: Binding<PlaceUI>,
         showingTagsSelector: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingTagsSelector = showingTagsSelector
        self.editEnabled = editEnabled
    }

    // MARK: - Body
    var body: some View {
        Group {
            VStack {
                HStack(alignment: .center) {
                    Text("common.tags")
                        .textStyle(.stringFieldTitle)
                        .padding(.leading, 10)

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
                    IcoButton(systemImage: "ellipsis",
                              icoSize: 14,
                              action: { showingTagsSelector.toggle() })
                        .padding(.trailing, 15)
                        .opacity(editEnabled ? 1 : 0)
                }
            }
            .padding(.vertical, 10)
            Divider()
                .padding(.horizontal)
        }
    }
}

#if DEBUG
struct MockPlaceTagsView: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var showingTagsSelector: Bool = true

    var body: some View {
        VStack {
            Divider()
            PlaceTagsView(place: $place,
                          showingTagsSelector: $showingTagsSelector,
                          editEnabled: true)
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(6)
    }
}

#Preview {
    NavigationStack {
        MockPlaceTagsView()
    }
}

#endif
