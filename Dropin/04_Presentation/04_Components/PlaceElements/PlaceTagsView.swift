//
//  PlaceTagsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceTagsView: View {
    
    enum PresentationMode {
        case inline
        case form
    }
    
    // MARK: - States & Bindings
    @Binding private var place: PlaceUI
    @Binding private var showingTagsSelector: Bool

    // MARK: - private vars
    private var editEnabled: Bool
    private var presentationMode: PresentationMode

    // MARK: - init
    init(place: Binding<PlaceUI>,
         showingTagsSelector: Binding<Bool>,
         editEnabled: Bool,
         presentationMode: PresentationMode = .inline) {
        self._place = place
        self._showingTagsSelector = showingTagsSelector
        self.editEnabled = editEnabled
        self.presentationMode = presentationMode
    }

    // MARK: - Body
    var body: some View {
        switch presentationMode {
            case .inline:
                inlineView
            case .form:
                formView
        }
    }
    
    private var inlineView: some View {
        Group {
            VStack {
                HStack(alignment: .center) {
                    Text("common.tags")
                        .textStyle(.stringFieldTitle)
                        .padding(.leading, 10)

                    if place.tags.count > 0 {
                        FlowLayout(alignment: .leading) {
                            let sortedTags = place.tags.sorted(by: { $0.name < $1.name && $0.createdAt < $1.createdAt })
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

    private var formView: some View {
        HStack(alignment: .center) {
            if place.tags.count > 0 {
                FlowLayout(alignment: .leading) {
                    let sortedTags = place.tags.sorted(by: { $0.name < $1.name && $0.createdAt < $1.createdAt })
                    ForEach(sortedTags) { tag in
                        TagView(name: tag.name, color: tag.color)
                    }
                }
                .padding()
            }
            Spacer()
            IcoButton(systemImage: "ellipsis",
                      icoSize: 14,
                      action: { showingTagsSelector.toggle() })
                .padding(.trailing, 15)
                .opacity(editEnabled ? 1 : 0)
        }
        .frame(minHeight: 55)
    }
}

#if DEBUG
struct MockPlaceTagsView: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var place1: PlaceUI
    @State var place2: PlaceUI
    @State var place3: PlaceUI
    @State var showingTagsSelector: Bool = true

    var body: some View {
        ZStack {
            Color.backgroundSecondary
                .ignoresSafeArea()
            VStack {
                Divider()
                PlaceTagsView(place: $place,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: true)
                Divider()
                Divider()
                Divider()
                PlaceTagsView(place: $place,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: true,
                              presentationMode: .form)
                    .background(.backgroundPrimary)

                    
                PlaceTagsView(place: $place1,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: true,
                              presentationMode: .form)
                    .background(.backgroundPrimary)
                PlaceTagsView(place: $place2,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: true,
                              presentationMode: .form)
                    .background(.backgroundPrimary)
                PlaceTagsView(place: $place3,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: true,
                              presentationMode: .form)
                    .background(.backgroundPrimary)

                    .border(.red)
            }
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(4)
        self.place1 = mock.getPlaceUI(5)
        self.place2 = mock.getPlaceUI(6)
        self.place3 = mock.getPlaceUI(7)
    }
}

#Preview {
    NavigationStack {
        MockPlaceTagsView()
    }
}

#endif
