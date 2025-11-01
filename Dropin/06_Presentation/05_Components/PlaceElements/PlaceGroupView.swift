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

    // MARK: - Body
    var body: some View {
        Group {
            VStack {
                HStack {
                    Text("common.group")
                        .font(.title3)
                        .foregroundStyle(.gray)
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
                        IcoButton(systemImage: "ellipsis", icoSize: 14)
                            .padding(.trailing, 15)
                            .onTapGesture {
                                showingGroupSelector.toggle()
                            }
                            .opacity(editEnabled ? 1 : 0)
                    }
                }
            }
            .frame(height: 75)
            Divider()
                .padding(.horizontal)
        }
    }
    
    init(place: Binding<PlaceUI>,
         showingGroupSelector: Binding<Bool>,
         editEnabled: Bool) {
        self._place = place
        self._showingGroupSelector = showingGroupSelector
        self.editEnabled = editEnabled
    }
}
