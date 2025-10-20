//
//  GroupSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import SwiftData

struct GroupSelectorView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: GroupSelectorViewModel
    @Binding private var place: PlaceUI
    @State private var createdGroupName: String = ""
    @State private var createdGroupColor: Color
    @State private var isShowingNameWarn = false
    private var selectedGroupId: Binding<String> {
        Binding<String>(
            get: {
                return place.group?.id ?? ""
            }, set: { value in
                guard value.count > 0 else {
                    place.group = nil
                    return
                }
                guard let selectedGroup = viewModel.groups.first(where: { group in
                    group.id == value
                }) else { return }
                place.group = selectedGroup
            })
    }
    
    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Text("group_selector.title")
                    .padding()
            }
            .padding(.top)
            Divider()
            selectionView
                .frame(height: 80)
            groupPickerView
            createGroupView
            Spacer()
        }
        .task {
            Task {
                do {
                    try await viewModel.loadGroups()
                } catch {
                    assertionFailure("Couldn't load groups")
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var groupPickerView: some View {
        VStack {
            Picker("common.groups", selection: selectedGroupId) {
                Text("group_selector.none").tag("")
                ForEach(viewModel.groups) { group in
                    Text(group.name).tag(group.id)
                }
            }
            .pickerStyle(.wheel)
            Divider()
        }
    }
    
    private var selectionView: some View {
        VStack {
            if let group = place.group {
                GroupView(name: group.name,
                          color: group.color,
                          hasDestructiveBt: true,
                          destructiveAction: {
                    place.group = nil
                })

            } else {
                Text("group_selector.none_selected")
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .padding()
            }
            Divider()
        }
    }
    
    private var createGroupView: some View {
        HStack() {
            @Bindable var place = place

            ZStack {
                ColorPicker("", selection: $createdGroupColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdGroupColor)
            }
            TextField("group_selector.new", text: $createdGroupName)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white)
                            Text("placeholder.group_name")
                                .bold()
                                .foregroundStyle(.red)
                        }
                    }
                }
            Spacer()
            IcoButton(systemImage: "plus").onTapGesture {
                guard !createdGroupName.isEmpty else {
                    withAnimation(.linear(duration: 0.5)) {
                        isShowingNameWarn.toggle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.linear(duration: 0.5)) {
                                isShowingNameWarn.toggle()
                            }
                        }
                    }
                    return
                }
                Task {
                    let newGroup = try await viewModel.createGroup(name: createdGroupName, color: createdGroupColor.hex)
                    place.group = newGroup
                    createdGroupName = ""
                    createdGroupColor = Color.random()
                }
            }
            .padding(.trailing, 15)
        }

    }
    
    // MARK: - init
    init(viewModel: GroupSelectorViewModel, place: Binding<PlaceUI>) {
        self._viewModel = State(initialValue: viewModel) 
        self._place = place
        _createdGroupColor = State(initialValue: Color.random())
    }
}


#if DEBUG
struct MockGroupSelectorView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createGroupSelectorView(place: $place)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(0)
    }
}

#Preview {
    MockGroupSelectorView()
}

#endif
