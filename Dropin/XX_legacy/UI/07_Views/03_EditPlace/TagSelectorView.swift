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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Place.self) private var place

    // MARK: - private vars
    private var remainings: [SDTag] {
        return tags.filter { tag in
            return !place.tags.contains(tag)
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
    }

    // MARK: - Subviews
    private var headerView: some View {
        Group {
            HStack {
                Text("tag_selector.title")
                    .padding()
            }
            Divider()
        }
    }
    
    private var selectedView: some View {
        Group {
            let hasTags = place.tags.count > 0
            Text(hasTags ? "tag_selector.selected" : "tag_selector.empty")
                .font(.callout)
                .foregroundStyle(.gray)
                .padding()
            
            if hasTags {
                FlowLayout(alignment: .leading) {
                    ForEach(place.tags) { tag in
                        TagView(name: tag.name, color: Color(rgba: tag.color))
                            .onTapGesture {
                                guard let index = place.tags.firstIndex(of: tag) else {
                                    assertionFailure("Couldn't remove tag \(tag.name) from selection")
                                    return
                                }
                                place.tags.remove(at: index)
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
                        TagView(name: tag.name, color: Color(rgba: tag.color))
                            .onTapGesture {
                                place.tags.append(tag)
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
            TextField("tag_selector.new", text: $createdTagName)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white)
                            Text("placeholder.tag_name")
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
                let colorHex = createdTagColor.hex
                let newTag = SDTag(name: createdTagName, colorHex: createdTagColor.hex)
                modelContext.insert(newTag)
                place.tags.append(newTag)
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
        for item in SDTag.all {
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
        TagSelectorView()
            .modelContainer(container)
            .environment(Place(sdPlace: SDPlace.l2))
    }
}

#Preview {
    TSVPreview()
}

#endif

