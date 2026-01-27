//
//  CreatePlaceBasics.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct CreatePlaceBasicsView: View {
    
    // MARK: - State & Bindings
    @Binding private var place: PlaceUI
    @Binding private var showingMarkerList: Bool
    @Binding private var showingTagsSelector: Bool
    @Binding private var showingGroupSelector: Bool
    private var isNameFocused: FocusState<Bool>.Binding

    // MARK: - Init
    init(place: Binding<PlaceUI>,
         showingMarkerList: Binding<Bool>,
         showingTagsSelector: Binding<Bool>,
         showingGroupSelector: Binding<Bool>,
         isNameFocused: FocusState<Bool>.Binding) {
        self._place = place
        self._showingMarkerList = showingMarkerList
        self._showingTagsSelector = showingTagsSelector
        self._showingGroupSelector = showingGroupSelector
        self.isNameFocused = isNameFocused
    }

    // MARK: - Body
    var body: some View {
        VStack {
            PlaceHeaderViewV2(place: $place,
                              showingMarkerList: $showingMarkerList,
                              editEnabled: true,
                              isNameFocused: isNameFocused)
            .padding(.bottom, 15)
            PlaceTagsView(place: $place,
                          showingTagsSelector: $showingTagsSelector,
                          editEnabled: true)
            PlaceGroupView(place: $place,
                           showingGroupSelector: $showingGroupSelector,
                           editEnabled: true)
        }
    }
}
