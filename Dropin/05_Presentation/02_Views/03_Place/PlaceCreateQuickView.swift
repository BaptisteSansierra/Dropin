//
//  PlaceCreateQuickView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct PlaceCreateQuickView: View {
    
    enum Result {
        case moreOptions
        case saved
        case none
    }

    static let sheetHeight: PresentationDetent = .medium
    
    // MARK: - State & Bindings
    @State private var viewModel: PlaceCreateQuickViewModel
    @State private var place: PlaceUIModel
    @Binding private var result: Result
    @FocusState private var isNameFocused

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: PlaceCreateQuickViewModel,
         place: PlaceUIModel,
         result: Binding<Result>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = State(initialValue: place)
        self._result = result
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.surface1
                .ignoresSafeArea()
            VStack(spacing: 0) {
                PlaceHeaderView(place: $place,
                                isNameFocused: $isNameFocused)
                .padding(.bottom)
                .padding(.top, 30)
                
                detailsView
                
                Spacer()
                MainButton(text: "create_place.save", action: createPlace)
                    .padding(.bottom, 20)
                TextButton(text: "create_place.moreOptions", action: moreOptions)
            }
            .padding(.horizontal)
        }
        .task {
            if place.address == nil {
                await fetchAddress()
            }
            await viewModel.getSuggestedCategory()
            if let category = viewModel.matchingCategory {
                place.category = category
            }
        }
        .sheet(isPresented: $viewModel.showingTagsSelector) {
            viewModel.createTagSelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingCategorySelector) {
            viewModel.createCategorySelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showingMarkerList) {
            // FIXME: that was moved out, no marker selection in quick create sheet at the moment
            MarkerListView(selected: $place.icon)
        }
        .alertOk(isPresented: $viewModel.missingName,
                 title: "alert.missing_name.title",
                 body: "alert.missing_name.body",
                 action: { isNameFocused = true })
    }

    // MARK: - Subviews
    private var detailsView: some View {
        VStack {
            tagsView
                .padding(.horizontal, 20)
            detailsSeparatorView
            categoriesView
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
        }
        .padding(.top, 10)
    }

    private var detailsSeparatorView: some View {
        Rectangle()
            .fill(.fieldBorder)
            .frame(height: 1)
            .padding(.leading, 55)
    }

    @ViewBuilder
    private var tagsView: some View {
        if place.tags.isEmpty {
            emptyTagsView
                .frame(height: 40)
        } else {
            filledTagsView
                .frame(height: 40)
        }
    }

    private var emptyTagsView: some View {
        HStack(spacing: 0) {
            Image(systemName: "tag")
                .textStyle(.subheadline, color: .textSecondary)
                .padding(.trailing)
            Text("common.tags")
                .textStyle(.subheadline, color: .textSecondary)
            Spacer()
            TextButton(text: "common.add", action: editTags)
        }
    }
    
    private var filledTagsView: some View {
        HStack(spacing: 0) {
            Image(systemName: "tag")
                .textStyle(.subheadline, color: .textSecondary)
                .padding(.trailing)
            
            ScrollView(.horizontal) {
                LazyHStack {
                    let tags = place.tags.defaultSorted().prefix(2)
                    ForEach(tags) { tag in
                        TagView(name: tag.name, color: tag.color)
                    }
                    if place.tags.count > 2 {
                        TagView(name: "+ \(place.tags.count - 2)", color: .backgroundPrimary)
                    }
                }
            }
            .scrollIndicators(.hidden)
            TextButton(text: "common.edit", action: editTags)
        }
    }

    @ViewBuilder
    private var categoriesView: some View {
        if let category = place.category {
            filledCategoryView(category)
                .frame(height: 40)
        } else {
            emptyCategoryView
        }
    }
    
    private var emptyCategoryView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(systemName: "folder")
                    .textStyle(.subheadline, color: .textSecondary)
                    .padding(.trailing)
                Text("common.category")
                    .textStyle(.subheadline, color: .textSecondary)
                Spacer()
                TextButton(text: "common.choose", action: editCategory)
            }
            .frame(height: 40)

            if let suggested = viewModel.suggestedCategoryName, place.category == nil {
                HStack {
                    HStack(spacing: 0) {
                        Image(systemName: "plus")
                            .textStyle(.footnote, color: .dropinPrimary)
                            .padding(.trailing, 5)
                        Text("common.create")
                            .textStyle(.footnote, color: .dropinPrimary)
                            .padding(.trailing, 5)
                        Text("\"\(suggested)\"")
                            .textStyle(.footnote, color: .dropinPrimary)
                    }
                    //.padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.dropinPrimary.opacity(0.15))
                            .stroke(.dropinPrimary,
                                    style: StrokeStyle(dash: [2, 3]))
                    }
                    .onTapGesture(perform: createSuggestedCategory)
                    Spacer()
                }
                .padding(.leading, 35)
                .padding(.vertical, 5)
            }
        }
    }
    
    private func filledCategoryView(_ category: CategoryUIModel) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "folder")
                .textStyle(.subheadline, color: .textSecondary)
                .padding(.trailing)
            CategoryView(category: category, style: .small)
                .onTapGesture {
                    editCategory()
                }
                .padding(.trailing, -10)
            Spacer()
            TextButton(text: "common.change", action: editCategory)
        }
    }

    // MARK: - Actions
    private func editTags() {
        viewModel.showingTagsSelector.toggle()
    }
    
    private func editCategory() {
        viewModel.showingCategorySelector.toggle()
    }

    private func fetchAddress() async {
        Log.debug("Fetch address from coords : \(place.coordinates)")
        // Fetch address from coords
        //place.address = String(localized: "create_place.fetching")
        do {
            let address = try await viewModel.fetchAddress(coords: place.coordinates)
            Log.debug("Address fetched : \(address)")
            self.place.address = address
        } catch is CancellationError {
        } catch {
            // Keep nil address, it will be fetched later (when online)
        }
    }
    
    private func createPlace() {
        Task {
            do {
                try await viewModel.save(place: place)
                result = .saved
                dismiss()
            } catch DomainError.Place.missingName {
                viewModel.missingName = true
            } catch {
                // TODO: handle failure
                fatalError("couldn't save place in DB: \(error)")
            }
        }
    }
    
    private func moreOptions() {
        result = .moreOptions
        dismiss()
        viewModel.pushCreatePlaceFullView(place: place)
    }
    
    private func createSuggestedCategory() {
        guard let suggestedName = viewModel.suggestedCategoryName else { return }
        let category = Category(name: suggestedName,
                                color: viewModel.poiColor?.hex ?? String.randomColor(),
                                icon: viewModel.suggestedCategoryIcon ?? Icon(sf: "question")! )
        place.category = CategoryMapper.toUI(category)
    }
}

#if DEBUG
struct MockPlaceCreateQuickView: View {
    var mock: MockContainer
    @State var place: PlaceUIModel
    @State var present: Bool = false
    @State var result: PlaceCreateQuickView.Result = .none

    var body: some View {
        MainButton(text: "go") {
            present.toggle()
        }
        .padding()
        .sheet(isPresented: $present) {
            mock.appContainer.createPlaceCreateQuickView(place: place,
                                                         result: $result,
                                                         poiCategory: .amusementPark)
                .presentationDetents([PlaceCreateQuickView.sheetHeight])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            present.toggle()
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        // Get a place with plenty of tags
        let places = mock.getAllPlaceUIModel().sorted(by: { p1, p2 in
            p1.tags.count > p2.tags.count
        })
        //for p in places {
        //    print("PLACE \(p.name) has \(p.tags.count) tags")
        //}
        place = places[0]
    }
}

#Preview {
    MockPlaceCreateQuickView()
        .environment(AppSettings())
}

#endif
