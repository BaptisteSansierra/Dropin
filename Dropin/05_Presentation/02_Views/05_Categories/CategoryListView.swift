//
//  CategoryListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct CategoryListView: View {
    
    // Create a specific struct so Now each row's body is its own observation context.
    private struct CategoryListRow: View {
        let category: CategoryUIModel
        var body: some View {
            CategoryView(category: category, style: .iconOnly)
        }
    }

    // MARK: - State & Bindings
    @State private var viewModel: CategoryListViewModel
    @Binding private var showingSideMenu: Bool
    
    // MARK: - private properties
    private var activeCategories: [CategoryUIModel] {
        viewModel.categories.filter { $0.isActive }
    }

    // MARK: - init
    init(viewModel: CategoryListViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(activeCategories.enumerated()), id: \.offset) { idx, category in
                            groupRow(category)
                                .frame(height: 65)
                                .padding(.horizontal)
                            Rectangle()
                                .fill(.fieldBorder)
                                .frame(height: 1)
                                .opacity(idx == activeCategories.count - 1 ? 0 : 1)
                                .padding(.leading)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.surface1)
                            .stroke(.fieldBorder)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                .scrollIndicators(.hidden)
            }
            .overlay {
                if activeCategories.isEmpty {
                    placeholderView
                }
            }
            .navigationTitle("common.categories")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CategoryNavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .onAppear {
                Task {
                    do {
                        try await viewModel.loadCategories()
                    } catch {
                        // TODO: handle error
                    }
                }
            }
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .alert("alert.remove_category_title",
                   isPresented: $viewModel.showingRemoveAlert,
                   presenting: viewModel.groupToRemove) { category in
                
                Button("common.cancel", role: .cancel) {
                    viewModel.groupToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    Task {
                        await deleteCategory(category.id)
                    }
                }
            } message: { category in
                if category.placeCount > 0 {
                    Text("alert.remove_category_body_\(category.name)_\(category.placeCount)")
                } else {
                    Text("alert.remove_category_empty_body_\(category.name)")
                }
            }
        }
    }
    
    var placeholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_categories.title", systemImage: "folder")
        } description: {
            Text("placeholder.no_categories.body")
        }
    }

    private func groupRow(_ category: CategoryUIModel) -> some View {
        HStack {
            let nPlaces = category.placeCount
            let txtColor: Color = nPlaces == 0 ? .textTertiary : .textPrimary
            CategoryListRow(category: category)
            Text(verbatim: category.name)
                .textStyle(.categorySticker,
                           color: txtColor)
            Spacer()
            Text("category_list_view.num_places_\(nPlaces)")
                .textStyle(.placeholder, color: txtColor)
        }
        .contentShape(Rectangle())
        .swipeActions {
            Button() {
                deleteCategoryCallback(category)
            } label: {
                Label("common.delete", systemImage: "trash")
            }
            .tint(.destructive)
        }
        .onTapGesture {
            viewModel.pushCategoryDetailsView(categoryId: category.id)
        }
    }
    
    // MARK: - Actions
    private func deleteCategoryCallback(_ category: CategoryUIModel) {
        viewModel.groupToRemove = category
        viewModel.showingRemoveAlert = true
    }
    
    private func deleteCategory(_ categoryId: UUID) async {
        guard let index = viewModel.categories.firstIndex(where: { $0.id == categoryId }) else {
            fatalError("couldn't find any category id '\(categoryId)' in list")
        }
        do {
            try await viewModel.softDeleteCategory(index)
        } catch {
            // TODO: handle error
            assertionFailure("couldn't delete category")
        }
    }
    
    private func createCategoryDetailsView(_ categoryId: UUID) -> CategoryDetailsView {
        guard let index = viewModel.categories.firstIndex(where: { $0.id == categoryId }) else {
            fatalError("couldn't find any category id '\(categoryId)' in list")
        }
        return viewModel.createCategoryDetailsView(category: viewModel.categories[index])
    }

    private func createCategoryMapView(_ categoryId: UUID) -> CategoryMapView {
        //guard let _ = categories.firstIndex(where: { $0.id == categoryId }) else {
        //    fatalError("couldn't find any category id '\(categoryId)' in list")
        //}
        return viewModel.createCategoryMapView(categoryId: categoryId)
    }
    
    private func createPlaceEditView(_ placeRef: PlaceUIModelRef) -> PlaceEditView {
        return viewModel.createPlaceEditView(place: placeRef.place)
    }

    @ViewBuilder
    private func resolveDestination(navigationItem: CategoryNavigationItem) -> some View {
        switch navigationItem {
            case .groupDetails(let categoryId):
                createCategoryDetailsView(categoryId)
            case .groupMap(let categoryId):
                createCategoryMapView(categoryId)
            case .groupPlace(let placeRef):
                createPlaceEditView(placeRef)
            case .undefinedDummyView:
                ZStack {
                    Color.orange
                    Text(verbatim: "To be implemented...")
                }
            default:
                ZStack {
                    Color.orange
                    Text(verbatim: "Undefined navigation item")
                }
                .onAppear {
                    assertionFailure("undefined navigation item \(navigationItem)")
                }
        }
    }
}


#if DEBUG

struct MockCategoryListView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createCategoryListView(showingSideMenu: $showingSideMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockCategoryListView()
    }
    .environment(AppSettings())
}

#endif
