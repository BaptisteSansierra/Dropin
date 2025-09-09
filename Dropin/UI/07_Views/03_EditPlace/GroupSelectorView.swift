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
    @State private var createdGroupName: String = ""
    @State private var createdGroupColor: Color
    @State private var isShowingNameWarn = false
    // DB
    @Query private var groups: [SDGroup]

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Place.self) private var place

    // MARK: - Body
    var body: some View {
        @Bindable var place = place
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
    }
    
    // MARK: - Subviews
    private var groupPickerView: some View {
        VStack {
            @Bindable var place = place

            Picker("common.groups", selection: $place.group) {
                Text("group_selector.none").tag(Optional<SDGroup>(nil))
                ForEach(groups) { group in
                    Text(group.name).tag(Optional(group))
                }
            }
            .pickerStyle(.wheel)
            Divider()
        }
    }
    
    private var selectionView: some View {
        VStack {
            @Bindable var place = place

            if let group = place.group {
                GroupView(name: group.name,
                          color: Color(rgba: group.colorHex),
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
                let newGroup = SDGroup(name: createdGroupName, colorHex: createdGroupColor.hex)
                modelContext.insert(newGroup)
                place.group = newGroup
                createdGroupName = ""
                createdGroupColor = Color.random()
            }
            .padding(.trailing, 15)
        }

    }
    
    // MARK: - init
    init() {
        _groups = Query(sort: [SortDescriptor(\SDGroup.name), SortDescriptor(\SDGroup.creationDate)])
        _createdGroupColor = State(initialValue: Color.random())
    }
}



#if DEBUG

private struct GSVPreview: View {
    let container: ModelContainer

    @Query var locations: [SDPlace]
    @Query var tags: [SDTag]

    init() {
        print("CREATE TSVPreview")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        for item in SDGroup.all {
            container.mainContext.insert(item)
        }

        do {
            try container.mainContext.save()
        } catch {
            print("COULDN t save DB")
        }
        print(container)
    }
    
    var body: some View {
        GroupSelectorView()
            .modelContainer(container)
            .environment(Place(sdPlace: SDPlace.l1))
    }
}

#Preview {
    GSVPreview()
}

#endif

