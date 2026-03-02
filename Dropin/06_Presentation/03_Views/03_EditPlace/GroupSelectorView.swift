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
    @State private var createdGroupIcon: Icon?
    @State private var isShowingNameWarn = false
    @State private var showingMarkerPicker = false
    @State private var markerCircleOpacity: CGFloat = 1
    @State private var markerPlaceholderOpacity: CGFloat
    @State private var markerPlaceholderColor: Color
    @State private var markerPlaceholderFont: Font

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Private properties
    private let markerPlaceholderOpacityDefault: CGFloat = 0.3
    private let markerPlaceholderColorDefault: Color = .textPrimary
    private let markerPlaceholderFontDefault: Font = .system(size: 15)
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
    
    // MARK: - init
    init(viewModel: GroupSelectorViewModel, place: Binding<PlaceUI>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        _createdGroupColor = State(initialValue: Color.random())
        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
        markerPlaceholderColor = markerPlaceholderColorDefault
        markerPlaceholderFont = markerPlaceholderFontDefault
    }

    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Text("group_selector.title")
                    .textStyle(.body)
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
        .fullScreenCover(isPresented: $showingMarkerPicker) {
            MarkerListView(selected: $createdGroupIcon)
        }
    }
    
    // MARK: - Subviews
    private var groupPickerView: some View {
        VStack {
            Picker("common.groups", selection: selectedGroupId) {
                Text("group_selector.none")
                    .tag("")
                    .textStyle(.body)
                ForEach(viewModel.groups) { group in
                    Text(group.name)
                        .tag(group.id)
                        .textStyle(.body)
                }
            }
            .pickerStyle(.wheel)
            Divider()
        }
    }
    
    private var selectionView: some View {
        VStack {
            if let group = place.group {
                GroupView(group: group,
                          actionType: .remove,
                          action: {
                    place.group = nil
                })

            } else {
                Text("placeholder.no_group")
                    .textStyle(.placeholder)
                    .padding()
            }
            Divider()
        }
    }
    
    private var createGroupView: some View {
        HStack(spacing: 0) {
            @Bindable var place = place
            // Color picker
            ZStack {
                ColorPicker("", selection: $createdGroupColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdGroupColor)
            }
            .frame(width: 50)
            .padding(.leading, 10)
            // Marker picker
            ZStack {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2))
                    .frame(width: 29, height: 29)
                    .foregroundStyle(.dropinPrimary)
                    .opacity(markerCircleOpacity)
                    .onTapGesture {
                        showingMarkerPicker.toggle()
                    }
                if let icon = createdGroupIcon {
                    IconView(icon: icon)
                        .sizeCaption()
                        .foregroundStyle(.dropinPrimary)
                } else {
                    Image(systemName: "tag")
                        .foregroundStyle(markerPlaceholderColor)
                        .font(markerPlaceholderFont)
                        .opacity(markerPlaceholderOpacity)
                }
            }
            .frame(width: 50)
            .padding(.vertical)
            .padding(.trailing, 10)
            // Group name
            TextField("group_selector.new", text: $createdGroupName)
                .textStyle(.body)
                //.border(.blue, width: 2)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.backgroundPrimary)
                            Text("placeholder.group_name")
                                .textStyle(.bodyError)
                        }
                    }
                }

            Spacer()
            IcoButton(systemImage: "plus") {
                createGroup()
            }
            .padding(.trailing, 15)
        }

    }

    // MARK: - private methods
    private func createGroup() {
        guard let groupIcon = createdGroupIcon else {
            withAnimation(.linear(duration: 0.25)) {
                markerCircleOpacity = 0
                markerPlaceholderColor = .warning
                markerPlaceholderFont = .system(size: 22)
                markerPlaceholderOpacity = 1
            } completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        markerCircleOpacity = 1
                        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
                        markerPlaceholderColor = markerPlaceholderColorDefault
                        markerPlaceholderFont = markerPlaceholderFontDefault
                    }
                }
            }
            return
        }
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
            let newGroup = try await viewModel.createGroup(name: createdGroupName,
                                                           color: createdGroupColor.hex,
                                                           icon: groupIcon)
            place.group = newGroup
            createdGroupName = ""
            createdGroupColor = Color.random()
            createdGroupIcon = nil
        }
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
