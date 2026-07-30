//
//  TagSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI
import SwiftData

#if true // NEW IMPLEMENTATION
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
        VStack(spacing: 0) {
            headerView
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !viewModel.placeTags.isEmpty {
                        section(title: Text("tag_selector.selected_count_\(viewModel.placeTags.count)")) {
                            FlowLayout(alignment: .leading) {
                                ForEach(viewModel.placeTags) { tag in
                                    TagView(name: tag.name, color: tag.color, style: .selected)
                                        .onTapGesture { removeTag(tag) }
                                }
                            }
                        }
                    }

                    section(title: Text("tag_selector.all")) {
                        FlowLayout(alignment: .leading) {
                            ForEach(viewModel.remainingTags) { tag in
                                TagView(name: tag.name, color: tag.color, style: .unselected)
                                    .onTapGesture { addTag(tag) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            createTagView
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
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
        Text("tag_selector.header")
            .textStyle(.bodySemibold)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func section<Title: View, Content: View>(title: Title,
                                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            title
                .textStyle(.formSectionTitle2)
                .textCase(.uppercase)
            content()
        }
    }

    private var createTagView: some View {
        HStack(spacing: 10) {
            // Color picker
            ZStack {
                ColorPicker(String(""), selection: $createdTagColor, supportsOpacity: false)
                    .labelsHidden()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdTagColor)
                    .allowsHitTesting(false)
            }
            .frame(width: 38, height: 38)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }

            // Tag name
            TextField("tag_selector.new", text: $createdTagName)
                .textStyle(.body)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.surface2)
                            Text("placeholder.tag_name")
                                .textStyle(.bodyError)
                        }
                    }
                }

//            MainButton(text: "common.add") {
//                
//            }
//            .frame(maxWidth: nil)
            
            Button {
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
            } label: {
                Text("common.add")
                    .textStyle(.mainButton, color: .surface1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(createdTagName.isEmpty ? .disabled : .dropinPrimary,
                                in: RoundedRectangle(cornerRadius: 10))
                    .opacity(createdTagName.isEmpty ? 0.45 : 1)
            }
            .buttonStyle(.plain)
            
            
            
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surface2)
        .overlay(alignment: .top) {
            Rectangle().fill(.fieldBorder).frame(height: 1)
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

#else // OLD IMPLEMENTATION
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
                    .textStyle(.body)
                    .padding()
            }
            Divider()
        }
    }

    private var selectedView: some View {
        Group {
            let hasTags = viewModel.placeTags.count > 0
            Text(hasTags ? "tag_selector.selected" : "placeholder.no_tags")
                .textStyle(.placeholder)
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
            // Color picker
            ZStack {
                ColorPicker(String(""), selection: $createdTagColor, supportsOpacity: false)
                    .labelsHidden()
                    .padding()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdTagColor)
            }
            // Tag name
            TextField("tag_selector.new", text: $createdTagName)
                .textStyle(.body)
                .autocorrectionDisabled()
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.backgroundPrimary)
                            Text("placeholder.tag_name")
                                .textStyle(.bodyError)
                        }
                    }
                }
            Spacer()
            IcoButton(systemImage: "plus") {
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
#endif


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
