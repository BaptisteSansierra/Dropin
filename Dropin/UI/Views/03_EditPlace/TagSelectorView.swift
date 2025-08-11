//
//  TagSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI
import SwiftData

struct TagSelectorView: View {
    
    // MARK: - State & Bindings
    @State private var createdTagName: String = ""
    @State private var createdTagColor: Color
    @State private var isShowingNameWarn = false
    // DB
    @Query var tags: [SDTag]

    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(PlaceFactory.self) private var placeFactory

    // MARK: - private vars
    private var remainings: [SDTag] {
        return tags.filter { tag in
            return !placeFactory.place.tags.contains(tag)
        }
    }

    // MARK: - Body
    var body: some View {
        VStack {
            headerView
            ScrollView {
                selectedView
                remainingView
                createTagView
            }
        }
//        .onFirstAppear {
//            output.selected = []
//            if let tags = placeFactory.place.tags {
//                output.selected = tags
//            }
//        }
    }

    // MARK: - Subviews
    private var headerView: some View {
        Group {
            HStack {
                Text("Select tags for this place")
                    .padding()
            }
            Divider()
        }
    }
    
    private var selectedView: some View {
        Group {
            let hasTags = placeFactory.place.tags.count > 0
            Text(hasTags ? "Selected tags" : "No tag selected")
                .font(.callout)
                .foregroundStyle(.gray)
                .padding()
            
            if hasTags {
                FlowLayout(alignment: .leading) {
                    ForEach(placeFactory.place.tags) { tag in
                        TagView(name: tag.name, color: Color(rgba: tag.colorHex))
                            .onTapGesture {
                                guard let index = placeFactory.place.tags.firstIndex(of: tag) else {
                                    assertionFailure("Couldn't remove tag \(tag.name) from selection")
                                    return
                                }
                                placeFactory.place.tags.remove(at: index)
                            }
                    }
                }
                .padding([.bottom, .leading, .trailing])
            }
            Divider()
        }
    }

    private var remainingView: some View {
        Group {
            if remainings.count > 0 {
                FlowLayout(alignment: .leading) {
                    ForEach(remainings) { tag in
                        TagView(name: tag.name, color: Color(rgba: tag.colorHex))
                            .onTapGesture {
                                placeFactory.place.tags.append(tag)
                            }
                    }
                }
                .padding()
                Divider()
            }
        }
    }
    
    private var createTagView: some View {
        HStack() {
            ZStack {
                ColorPicker("", selection: $createdTagColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdTagColor)
            }
            TextField("New tag", text: $createdTagName)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white)
                            Text("Give tag a name")
                                .bold()
                                .foregroundStyle(.red)
                        }
                    }
                }
            Spacer()
            IcoButton(systemImage: "plus").onTapGesture {
                guard !createdTagName.isEmpty else {
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
                let newTag = SDTag(name: createdTagName, colorHex: createdTagColor.hex)
                modelContext.insert(newTag)
                placeFactory.place.tags.append(newTag)
                createdTagName = ""
                createdTagColor = Color.random()
            }
            .padding(.trailing, 15)
        }
    }

    // MARK: - init
    init() {
        _tags = Query(sort: [SortDescriptor(\SDTag.name), SortDescriptor(\SDTag.creationDate)])

        _createdTagColor = State(initialValue: Color.random())
    }
}

#if DEBUG

private struct TSVPreview: View {
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
        container.mainContext.insert(SDTag.t1)
        container.mainContext.insert(SDTag.t2)
        container.mainContext.insert(SDTag.t3)
        container.mainContext.insert(SDTag.t4)
        container.mainContext.insert(SDTag.t5)
        container.mainContext.insert(SDTag.t6)
        container.mainContext.insert(SDTag.t7)
        container.mainContext.insert(SDTag.t8)
        container.mainContext.insert(SDTag.t9)
        container.mainContext.insert(SDTag.t10)
        container.mainContext.insert(SDTag.t11)
        
        container.mainContext.insert(SDPlace.l1)
        container.mainContext.insert(SDPlace.l2)
        
        do {
            try container.mainContext.save()
        } catch {
            print("COULDN t save DB")
        }
        print(container)
    }
    
    var body: some View {
        TagSelectorView()
            .modelContainer(container)
            .environment(PlaceFactory.preview)
    }
}

#Preview {
    TSVPreview()
}

#endif

