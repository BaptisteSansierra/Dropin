//
//  PlaceGroupView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import SwiftUI

struct PlaceGroupView: View {
    
    // MARK: - States & Bindings
    @Binding private var place: PlaceUI
    @Binding private var showingGroupSelector: Bool
    
    // MARK: - private vars
    private var editEnabled: Bool

    // MARK: - Init
    init(place: Binding<PlaceUI>,
         showingGroupSelector: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingGroupSelector = showingGroupSelector
        self.editEnabled = editEnabled
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            VStack {
                HStack {
                    Text("common.group")
                        .textStyle(.stringFieldTitle)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                    Spacer()
                    
                    if let group = place.group {
                        GroupView(group: group,
                                  actionType: editEnabled ? .remove : .none,
                                  action: {
                            place.group = nil
                        })
                        .padding(.trailing)
                    } else {
                        IcoButton(systemImage: "ellipsis",
                                  icoSize: 14,
                                  action: { showingGroupSelector.toggle() })
                            .padding(.trailing, 15)
                            .opacity(editEnabled ? 1 : 0)
                    }
                }
            }
            .frame(height: 65)
            Divider()
                .padding(.horizontal)
        }
    }
}


#if DEBUG
struct MockPlaceGroupView: View {
    var mock: MockContainer
    @State var place: PlaceUI
    @State var showingGroupSelector: Bool = true

    var body: some View {
        VStack {
            Divider()
            PlaceGroupView(place: $place,
                           showingGroupSelector: $showingGroupSelector,
                           editEnabled: true)
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(2)
    }
}

#Preview {
    NavigationStack {
        MockPlaceGroupView()
    }
}

#endif
