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
    @State private var viewModel: TagSelectorViewModel
    @Binding private var place: PlaceUI
    @State private var createdTagName: String = ""
    @State private var createdTagColor: Color
    @State private var isShowingNameWarn = false

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: TagSelectorViewModel, place: Binding<PlaceUI>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        _createdTagColor = State(initialValue: Color.random())
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
        .task {
            Task {
                do {
                    try await viewModel.loadTags()
                    viewModel.updateData(place)
                } catch {
                    assertionFailure("Couldn't load groups")
                }
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
            let hasTags = viewModel.placeTags.count > 0
            Text(hasTags ? "tag_selector.selected" : "tag_selector.empty")
                .font(.callout)
                .foregroundStyle(.gray)
                .padding()
          
            if hasTags {
                FlowLayout(alignment: .leading) {
                    ForEach(viewModel.placeTags) { tag in
                        TagView(name: tag.name, color: tag.color)
                            .onTapGesture {
                                Task {
                                    removeTag(tag)
                                }
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
            if viewModel.remainingTags.count > 0 {
                FlowLayout(alignment: .leading) {
                    ForEach(viewModel.remainingTags) { tag in
                        TagView(name: tag.name, color: tag.color)
                            .onTapGesture {
                                Task {
                                    addTag(tag)
                                }
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
                Task {
                    let newTag = try await viewModel.createTag(name: createdTagName, color: createdTagColor.hex)
                    addTag(newTag)
                    createdTagName = ""
                    createdTagColor = Color.random()
                }
            }
            .padding(.trailing, 15)
        }
    }
    
    private func addTag(_ tag: TagUI) {
        place.tags.append(tag)
        viewModel.updateData(place)
    }

    private func removeTag(_ tag: TagUI) {
        guard let index = place.tags.firstIndex(where: { $0.id == tag.id }) else {
            assertionFailure("Couldn't remove tag \(tag.name) from selection")
            return
        }
        place.tags.remove(at: index)
        viewModel.updateData(place)
    }
}


#if DEBUG
struct MockTagSelectorView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createTagSelectorView(place: $place)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
    }
}

#Preview {
    MockTagSelectorView()
}

#endif



