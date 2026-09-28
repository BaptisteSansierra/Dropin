//
//  PlaceFilterView.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/4/26.
//

import SwiftUI

struct PlaceFilterView: View {
    
    // MARK: States & Bindings
    @State private var viewModel: PlaceFilterViewModel
    @State private var filter: PlaceFilter
    @Environment(\.dismiss) private var dismiss
    
    // MARK: private props
    let unselectOpacity: CGFloat = 0.5
    
    // MARK: init
    init(viewModel: PlaceFilterViewModel) {
        self.viewModel = viewModel
        
        if let srcFilter = viewModel.filter.wrappedValue {
            filter = srcFilter
        } else {
            filter = PlaceFilter()
        }
    }
    
    // MARK: body
    var body: some View {
        VStack {
            headerView
            ScrollView {
                categoriesView
                Divider()
                    .padding(.leading)
                tagsView
            }
            Spacer()
            bottomView
        }
        .presentationBackground(.backgroundPrimary)
        .task {
            Task {
                try? await viewModel.loadData()
                // TODO: handle errors
            }
        }
    }
    
    // MARK: subviews
    private var headerView: some View {
        VStack {
            HStack {
                Text("place_filter_view.title")
                    .textStyle(.formSectionTitle, color: .textPrimary)
                    .padding(.leading)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.surface1)
                            .stroke(.fieldBorder)
                            .frame(width: 35, height: 35)
                        Image(systemName: "multiply")
                            .textStyle(.body)
                    }
                    .padding(.trailing)
                }
            }
            .padding(.top, 25)
            Divider()
        }
    }
    
    private var categoriesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "common.categories").uppercased())
                    .textStyle(.formSectionTitle2, color: .textSecondary)
                Spacer()
                TextButton(text: "common.clear", textStyle: .smallButton) {
                    clearCategories()
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)

            FlowLayout(alignment: .leading) {
                CategoryView(name: String(localized: "common.uncategorized"),
                          color: .gray,
                          icon: nil,
                          style: .small)
                    .if( !filter.includeUncategorized ) { view in
                        view.opacity(unselectOpacity)
                    }
                    .onTapGesture {
                        filter.includeUncategorized.toggle()
                    }

                ForEach(viewModel.categories) { category in
                    CategoryView(category: category, style: .small)
                        .if( !filter.categoryIDs.contains(category.id) ) { view in
                            view.opacity(unselectOpacity)
                        }
                        .onTapGesture {
                            toggle(category)
                        }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .padding(.bottom, 15)
        }
    }
    
    private var tagsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "common.tags").uppercased())
                    .textStyle(.formSectionTitle2, color: .textSecondary)
                Spacer()
                TextButton(text: "common.clear", textStyle: .smallButton) {
                    clearTags()
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)

            FlowLayout(alignment: .leading) {
                TagView(name: String(localized: "placeholder.no_tags"),
                        color: .backgroundPrimary,
                        style: filter.includeUntagged ? .selected : .unselected)
                    .if( !filter.includeUntagged ) { view in
                        view.opacity(unselectOpacity)
                    }
                    .onTapGesture {
                        filter.includeUntagged.toggle()
                    }
                
                ForEach(viewModel.tags) { tag in
                    TagView(name: tag.name,
                            color: tag.color,
                            style: filter.tagIDs.contains(tag.id) ? .selected : .unselected)
                        .if( !filter.tagIDs.contains(tag.id), action: { view in
                            view.opacity(unselectOpacity)
                        })
                        .onTapGesture {
                            toggle(tag)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private var bottomView: some View {
        HStack(spacing: 0) {
            SecondaryButton(text: "common.clear_all") {
                clear()
            }
            .padding(.trailing)
            MainButton(text: "common.apply") {
                apply()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: private methods
    private func toggle(_ category: CategoryUIModel) {
        if filter.categoryIDs.contains(category.id) {
            filter.categoryIDs.remove(category.id)
        } else {
            filter.categoryIDs.insert(category.id)
        }
    }
    
    private func toggle(_ tag: TagUIModel) {
        if filter.tagIDs.contains(tag.id) {
            filter.tagIDs.remove(tag.id)
        } else {
            filter.tagIDs.insert(tag.id)
        }
    }

    private func clearCategories() {
        filter.categoryIDs.removeAll()
        filter.includeUncategorized = false
    }
    
    private func clearTags() {
        filter.tagIDs.removeAll()
        filter.includeUntagged = false
    }

    private func clear() {
        filter = PlaceFilter()
        apply()
    }

    private func apply() {
        defer {
            dismiss()
        }
        guard filter.isActive else {
            viewModel.filter.wrappedValue = nil
            return
        }
        viewModel.filter.wrappedValue = filter
    }
}

#if DEBUG

struct MockPlaceFilterView: View {

    var mock = MockContainer()
    @State var filter: PlaceFilter? = PlaceFilter()

    init() {
    }
    
    var body: some View {
        mock.appContainer.createPlaceFilterView(filter: $filter)
    }
}

#Preview {
    @Previewable @State var presented: Bool = false
    ZStack {
        Color.purple.opacity(0.1)
        Button("TGL") {
            presented.toggle()
        }
    }
    .sheet(isPresented: $presented) {
        MockPlaceFilterView()
            .presentationDragIndicator(.visible)
    }
    .task {
        presented = true
    }
}
    
#endif
