//
//  GroupSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import SwiftData

#if true // NEW IMPLEMENTATION
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
        VStack(spacing: 0) {
            headerView
                .padding(.top, 12)
                .padding(.horizontal, 20)

            ScrollView {
                listView
                    .padding(.top, 16)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }

            createGroupView
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
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

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 6) {
            Text("group_selector.header")
                .textStyle(.bodySemibold)
            Text("group_selector.hint")
                .textStyle(.caption, color: .textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - List
    private var listView: some View {
        VStack(spacing: 0) {
            row(name: String(localized: "group_selector.none"),
                isSelected: place.group == nil) {
                noGroupTile
            } action: {
                place.group = nil
                dismiss()
            }

            ForEach(viewModel.groups) { group in
                rowDivider
                row(name: group.name,
                    isSelected: place.group?.id == group.id) {
                    groupTile(group)
                } action: {
                    place.group = group
                    dismiss()
                }
            }
        }
        .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.fieldBorder, lineWidth: 1)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(rgba: "#EEE5D5"))
            .frame(height: 1)
            .padding(.leading, 59)
    }

    @ViewBuilder
    private func row<Tile: View>(name: String,
                                 isSelected: Bool,
                                 @ViewBuilder tile: () -> Tile,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                tile()
                Text(name)
                    .textStyle(isSelected ? .bodySemibold : .body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.dropinPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(isSelected ? Color.dropinPrimary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var noGroupTile: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(.backgroundTertiary)
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
    }

    private func groupTile(_ group: GroupUI) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(group.color)
            .frame(width: 30, height: 30)
            .overlay {
                IconView(icon: group.icon)
                    .sizeCallout()
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Create bar
    private var createGroupView: some View {
        HStack(spacing: 10) {
            // Color picker
            ZStack {
                ColorPicker(String(""), selection: $createdGroupColor, supportsOpacity: false)
                    .labelsHidden()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdGroupColor)
                    .allowsHitTesting(false)
            }
            .frame(width: 38, height: 38)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }

            // Marker picker
            ZStack {
                if let icon = createdGroupIcon {
                    IconView(icon: icon)
                        .sizeCallout()
                        .foregroundStyle(.dropinPrimary)
                } else {
                    Image(systemName: "tag")
                        .foregroundStyle(markerPlaceholderColor)
                        .font(markerPlaceholderFont)
                        .opacity(markerPlaceholderOpacity)
                }
            }
            .frame(width: 38, height: 38)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }
            .opacity(markerCircleOpacity)
            .onTapGesture {
                showingMarkerPicker.toggle()
            }

            // Group name
            TextField("group_selector.new", text: $createdGroupName)
                .textStyle(.body)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.surface2)
                            Text("placeholder.group_name")
                                .textStyle(.bodyError)
                        }
                    }
                }

            Button {
                createGroup()
            } label: {
                Text("common.add")
                    .textStyle(.mainButton)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.dropinPrimary, in: RoundedRectangle(cornerRadius: 10))
                    .opacity(createdGroupName.isEmpty ? 0.45 : 1)
            }
            .buttonStyle(.plain)
            .disabled(createdGroupName.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surface2)
        .overlay(alignment: .top) {
            Rectangle().fill(.fieldBorder).frame(height: 1)
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
            dismiss()
        }
    }
}

#else // OLD IMPLEMENTATION
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
                return place.group?.id.uuidString ?? ""
            }, set: { value in
                guard value.count > 0 else {
                    place.group = nil
                    return
                }
                let uuid = UUID(uuidString: value)
                guard let selectedGroup = viewModel.groups.first(where: { group in
                    group.id == uuid
                }) else {
                    return
                }
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
                        .tag(group.id.uuidString)
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
            // Color picker
            ZStack {
                ColorPicker(String(""), selection: $createdGroupColor, supportsOpacity: false)
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
#endif


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
