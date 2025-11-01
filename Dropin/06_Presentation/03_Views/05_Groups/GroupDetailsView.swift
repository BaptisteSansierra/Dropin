//
//  GroupDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/9/25.
//

import SwiftUI

struct GroupDetailsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: GroupDetailsViewModel
    @Binding private var group: GroupUI
    @State private var groupColor: Color
    @State private var showingRemoveAlert: Bool = false
    @State private var showingMarkerList: Bool = false

    // MARK: - Env
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: GroupDetailsViewModel, group: Binding<GroupUI>) {
        self.viewModel = viewModel
        self._group = group
        self._groupColor = State(initialValue: group.wrappedValue.color)
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                GroupView(group: group)
                Spacer()
            }
            .padding(.top, 15)
            .padding(.bottom, 20)

            nameView

            colorView
            
            sfSymbolView
            
            placesView

            Spacer()
            
            deleteButton
        }
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .alert("alert.remove_group_title",
               isPresented: $showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteGroup(group)
                        dismiss()
                    } catch {
                        print("Could not delete group \(group.name): \(error)")
                    }
                }
            }
        } message: {
            if group.places.count > 0 {
                Text("alert.remove_group_body_\(group.name)_\(group.places.count)")
            } else {
                Text("alert.remove_group_empty_body_\(group.name)")
            }
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: Binding<String>(
                get: {
                    return group.sfSymbol
                }, set: { value in
                    group.sfSymbol = value
                    Task {
                        try await viewModel.updateGroup(group)
                    }
                }))
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.group_name")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.leading, 40)
                .foregroundStyle(.gray)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.white)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                TextField("common.group_name", text: $group.name)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 40)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        updateGroup()
                    }
            }
        }
    }
    
    private var colorView: some View {
        VStack(alignment: .leading) {
            Text("common.group_color")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.leading, 40)
                .padding(.top, 10)
                .foregroundStyle(.gray)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.white)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                HStack() {
                    RoundedRectangle(cornerSize: 8)
                        .frame(height: 25)
                        .frame(width: 100)
                        .foregroundStyle(groupColor)
                        .padding(.leading, 40)
                        //.padding(.trailing, 40)
                    Spacer()
                    ColorPicker("", selection: $groupColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: groupColor) { oldValue, newValue in
                            group.color = groupColor
                            updateGroup()
                        }
                }
            }
        }
    }
    
    private var sfSymbolView: some View {
        VStack(alignment: .leading) {
            Text("common.group_symbol")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.leading, 40)
                .padding(.top, 10)
                .foregroundStyle(.gray)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.white)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                
                HStack {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerSize: 8)
                            .strokeBorder(.black, style: StrokeStyle(lineWidth: 1))
                            .frame(height: 25)
                            .frame(width: 100)
                            .foregroundStyle(.clear)
                        Image(systemName: group.sfSymbol)
                            .font(.system(size: 14))
                    }
                    .padding(.leading, 40)
                    Spacer()
                    IcoButton(systemImage: "ellipsis", icoSize: 14)
                        .padding(0)
                        .onTapGesture {
                            showingMarkerList.toggle()
                        }
                        .padding(.trailing, 40)
                }
            }
        }
    }

    private var placesView: some View {
        VStack(alignment: .leading) {
            if group.places.count > 0 {
                Text("common.related_places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 40)
                    .padding(.top, 30)
                    .foregroundStyle(.gray)
                Divider()
                List {
                    ForEach(group.places) { place in
                        PlaceRowView(place: place)
                        .swipeActions(allowsFullSwipe: false) {
                            Button() {
                                guard let idx = group.places.firstIndex(where: { place.id == $0.id }) else { return }
                                group.places.remove(at: idx)
                                updateGroup()
                            } label: {
                                Text("common.unlink")
                            }
                            .tint(.red)
                        }
                    }
                }
            } else {
                Text("common.no_related_places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 40)
                    .padding(.top, 30)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private var deleteButton: some View {
        ZStack {
            RoundedRectangle(cornerSize: 8)
                .foregroundStyle(.red)
                .frame(width: DropinApp.ui.button.width,
                       height: DropinApp.ui.button.height)
            Text("common.delete_group")
                .foregroundStyle(.white)
        }
        .padding(.bottom, 15)
        .onTapGesture {
            showingRemoveAlert = true
        }
    }

    // MARK: private methods
    private func updateGroup() {
        Task {
            do {
                try await viewModel.updateGroup(group)
            } catch {
                // TODO: handle error
                assertionFailure("Could not delete update group")
            }
        }
    }
}


#if DEBUG

struct MockGroupDetailsView: View {
    var mock: MockContainer
    @State private var group: GroupUI

    var body: some View {
        mock.appContainer.createGroupDetailsView(group: $group)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.group = mock.getGroupUI(0)
    }
}

#Preview {
    NavigationStack {
        MockGroupDetailsView()
            .environment(NavigationContext())
            .environment(LocationManager())
    }
}

#endif
