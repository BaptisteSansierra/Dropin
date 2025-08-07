//
//  TagSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI
import SwiftData


//@Observable class TagSelectorOutput {
//
//    var selected: [SDTag]
//
//    init() {
//        self.selected = []
//    }
//
//    init(selected: [SDTag]) {
//        self.selected = selected
//    }
//}


//@Observable class TagSelectorModelView {
//    
//    var tags: [SDTag]
//    var remainings: [SDTag] {
//        tags.filter { tag in
//            return !selected.contains(tag)
//        }
//    }
//    var selected: [SDTag]
//
//    init(tags: [SDTag], selected: [SDTag]) {
//        self.tags = tags
//        self.selected = selected
//    }
//}

struct TagSelectorView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    //@Environment(TagSelectorOutput.self) private var output
    @Environment(PlaceFactory.self) private var placeFactory

    @Query var tags: [SDTag]
    
    @State private var createdTagName: String = ""
    @State private var createdTagColor: Color
    @State private var isShowingNameWarn = false

    private var remainings: [SDTag] {
        return tags.filter { tag in
            return !placeFactory.place.tags.contains(tag)
        }
    }

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Text("Select tags for this place")
                        .padding()
                    
//                    HStack {
//                        Spacer()
//                        Button("", systemImage: "xmark.circle") {
//                            dismiss()
//                        }
//                        .padding()
//                        .tint(.dropinPrimary)
//                    }
                }
            }
            Divider()
            ScrollView {
                
                let hasTags = placeFactory.place.tags.count > 0
                Text(hasTags ? "Selected tags" : "No tag selected")
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .padding()
                
                
                //if output.selected.count > 0 {
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
                }
            }
            //.frame(maxHeight: 300)
            
        }
//        .onFirstAppear {
//            output.selected = []
//            if let tags = placeFactory.place.tags {
//                output.selected = tags
//            }
//        }
    }
    
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
//            .environment(TagSelectorOutput())
            .environment(PlaceFactory.preview)
    }
}

#Preview {
    TSVPreview()
}

#endif

