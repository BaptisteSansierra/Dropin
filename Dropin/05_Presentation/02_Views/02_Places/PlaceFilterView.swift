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
                groupsView
                Divider()
                    .padding(.leading)
                tagsView
            }
            Spacer()
            bottomView
        }
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
                    .textStyle(.formSectionTitle)
                    .padding(.leading)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.backgroundSecondary)
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
    
    private var groupsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(localized: "common.groups").uppercased())
                    .textStyle(.formSectionTitle2)
                    .padding(.leading)
                Spacer()
            }
            .padding(.top, 10)
            FlowLayout(alignment: .leading) {
                GroupView(name: String(localized: "common.not_grouped"),
                          color: .gray,
                          icon: nil,
                          size: .small)
                    .if( !filter.includeUngrouped ) { view in
                        view.opacity(unselectOpacity)
                    }
                    .onTapGesture {
                        filter.includeUngrouped.toggle()
                    }

                ForEach(viewModel.groups) { group in
                    GroupView(group: group, size: .small)
                        .if( !filter.groupIDs.contains(group.id) ) { view in
                            view.opacity(unselectOpacity)
                        }
                        .onTapGesture {
                            toggle(group)
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
                    .textStyle(.formSectionTitle2)
                    .padding(.leading)
                Spacer()
            }
            .padding(.top, 10)
            FlowLayout(alignment: .leading) {
                TagView(name: String(localized: "placeholder.no_tags"), color: .backgroundPrimary)
                    .if( !filter.includeUntagged ) { view in
                        view.opacity(unselectOpacity)
                    }
                    .onTapGesture {
                        filter.includeUntagged.toggle()
                    }
                
                ForEach(viewModel.tags) { tag in
                    TagView(name: tag.name, color: tag.color)
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
        HStack {
            SecondaryButton(text: "common.clear") {
                clear()
            }
            .padding(.leading)
            MainButton(text: "common.apply") {
                apply()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: private methods
    private func toggle(_ group: GroupUI) {
        if filter.groupIDs.contains(group.id) {
            filter.groupIDs.remove(group.id)
        } else {
            filter.groupIDs.insert(group.id)
        }
    }
    
    private func toggle(_ tag: TagUI) {
        if filter.tagIDs.contains(tag.id) {
            filter.tagIDs.remove(tag.id)
        } else {
            filter.tagIDs.insert(tag.id)
        }
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
