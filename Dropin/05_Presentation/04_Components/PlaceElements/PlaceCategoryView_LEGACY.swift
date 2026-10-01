//
//  PlaceCategoryView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

// FIXME: obsolete code

#if false

import SwiftUI

struct PlaceCategoryView: View {
    
    enum PresentationMode {
        case inline
        case form
    }
    
    // MARK: - States & Bindings
    @Binding private var place: PlaceUIModel
    @Binding private var showingCategorySelector: Bool
    
    // MARK: - private vars
    private var editEnabled: Bool
    private var presentationMode: PresentationMode

    // MARK: - Init
    init(place: Binding<PlaceUIModel>,
         showingCategorySelector: Binding<Bool>,
         editEnabled: Bool,
         presentationMode: PresentationMode = .inline) {
        self._place = place
        self._showingCategorySelector = showingCategorySelector
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
                HStack {
                    Text("common.category")
                        .textStyle(.stringFieldTitle)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                    Spacer()
                    
                    if let category = place.category {
                        CategoryView(category: category,
                                  actionType: editEnabled ? .remove : .none,
                                  action: {
                            place.category = nil
                        })
                        .padding(.trailing)
                    } else {
                        IcoButton(systemImage: "ellipsis",
                                  icoSize: 14,
                                  action: { showingCategorySelector.toggle() })
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
    
    private var formView: some View {
        HStack {
            Spacer()
            if let category = place.category {
                CategoryView(category: category,
                          actionType: editEnabled ? .remove : .none,
                          action: {
                    place.category = nil
                })
                .padding(.vertical, 20)
                .padding(.trailing)
            } else {
                IcoButton(systemImage: "ellipsis",
                          icoSize: 14,
                          action: { showingCategorySelector.toggle() })
                    .padding(.trailing, 15)
                    .opacity(editEnabled ? 1 : 0)
            }
        }
        .frame(minHeight: 55)
    }
}


#if DEBUG
struct MockPlaceCategoryView: View {
    var mock: MockContainer
    @State var place: PlaceUIModel
    @State var showingCategorySelector: Bool = true

    var body: some View {
        VStack {
            Divider()
            PlaceCategoryView(place: $place,
                           showingCategorySelector: $showingCategorySelector,
                           editEnabled: true)
            Divider()
            Divider()
            Divider()
            PlaceCategoryView(place: $place,
                           showingCategorySelector: $showingCategorySelector,
                           editEnabled: true,
                           presentationMode: .form)
            .border(.red)

        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUIModel(2)
    }
}

#Preview {
    NavigationStack {
        MockPlaceCategoryView()
    }
}

#endif

#endif
