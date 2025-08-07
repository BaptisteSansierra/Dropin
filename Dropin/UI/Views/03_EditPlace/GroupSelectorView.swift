//
//  GroupSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import SwiftData

struct GroupSelectorView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(PlaceFactory.self) private var placeFactory
    
    @Query private var groups: [SDGroup]
    
    @State private var createdGroupName: String = ""
    @State private var createdGroupColor: Color
    @State private var isShowingNameWarn = false

    var body: some View {
        @Bindable var place = placeFactory.place
        VStack {
            HStack {
                Text("Should this place be in a group ?")
                    .padding()
            }
            .padding(.top)
            Divider()
            VStack {
                if let group = place.group {
                    GroupView(name: group.name,
                              color: Color(rgba: group.colorHex),
                              hasDestructiveBt: true,
                              destructiveAction: {
                        place.group = nil
                    })

                } else {
                    Text("No group selected")
                        .font(.callout)
                        .foregroundStyle(.gray)
                        .padding()
                }
                Divider()
            }
            .frame(height: 80)

            Picker("Groups", selection: $place.group) {
                Text("No group").tag(Optional<SDGroup>(nil))
                ForEach(groups) { group in
                    Text(group.name).tag(Optional(group))
                }
            }
            .pickerStyle(.wheel)
            Divider()

            // Create a group
            HStack() {
                ZStack {
                    ColorPicker("", selection: $createdGroupColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding()
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(createdGroupColor)
                }
                TextField("New group", text: $createdGroupName)
                    .autocorrectionDisabled()
                    .overlay {
                        if isShowingNameWarn {
                            ZStack(alignment: .leading) {
                                Rectangle().fill(.white)
                                Text("Give group a name")
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
            }
            Spacer()
        }
    }
    
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
        container.mainContext.insert(SDGroup.g1)
        container.mainContext.insert(SDGroup.g2)
        container.mainContext.insert(SDGroup.g3)
        container.mainContext.insert(SDGroup.g4)
        container.mainContext.insert(SDGroup.g5)
        
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
            .environment(PlaceFactory.preview)
    }
}

#Preview {
    GSVPreview()
}

#endif

