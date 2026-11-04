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
    @Binding private var place: PlaceUIModel

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: TagSelectorViewModel, place: Binding<PlaceUIModel>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 25)

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

            TagCreateView(existing: viewModel.tags.map({ $0.name }),
                          onCreate: createTag)

        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .task {
            Task {
                do {
                    try await viewModel.loadTags()
                    viewModel.updateData(place)
                } catch {
                    assertionFailure("Couldn't load categories")
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

    private func addTag(_ tag: TagUIModel) {
        place.tags.append(tag)
        viewModel.updateData(place)
    }

    private func removeTag(_ tag: TagUIModel) {
        guard let index = place.tags.firstIndex(where: { $0.id == tag.id }) else {
            assertionFailure("Couldn't remove tag \(tag.name) from selection")
            return
        }
        place.tags.remove(at: index)
        viewModel.updateData(place)
    }
    
    private func createTag(name: String, color: String) {
        Task {
            let newTag = try await viewModel.createTag(name: name,
                                                       color: color)
            addTag(newTag)
        }
    }
}

#if DEBUG
struct MockTagSelectorView: View {
    var mock: MockContainer
    @State var place: PlaceUIModel
    @State var present: Bool = false

    var body: some View {
        MainButton(text: "go") {
            present.toggle()
        }
        .padding()
        .sheet(isPresented: $present) {
            mock.appContainer.createTagSelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUIModel(1)
    }
}

#Preview {
    MockTagSelectorView()
}

#endif
