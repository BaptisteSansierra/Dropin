//
//  CategorySelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import SwiftData


// TODO: fix animation when keboard appears
struct CategorySelectorView: View {

    // MARK: - State & Bindings
    @State private var viewModel: CategorySelectorViewModel
    @Binding private var place: PlaceUIModel
    @State private var createdCategoryName: String = ""
    @State private var createdCategoryColor: Color
    @State private var createdCategoryIcon: Icon?
    @State private var isShowingNameWarn = false
    @State private var showingMarkerPicker = false
    @State private var markerCircleOpacity: CGFloat = 1
    @State private var markerPlaceholderOpacity: CGFloat
    @State private var markerPlaceholderColor: Color
    @State private var markerPlaceholderFont: Font
    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Private properties
    private let markerPlaceholderOpacityDefault: CGFloat = 0.3
    private let markerPlaceholderColorDefault: Color = .textPrimary
    private let markerPlaceholderFontDefault: Font = .system(size: 15)

    // MARK: - init
    init(viewModel: CategorySelectorViewModel, place: Binding<PlaceUIModel>) {
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        _createdCategoryColor = State(initialValue: Color.random())
        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
        markerPlaceholderColor = markerPlaceholderColorDefault
        markerPlaceholderFont = markerPlaceholderFontDefault
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 25)
                .padding(.horizontal, 20)

            ScrollView {
                listView
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
            .padding(.top, 16)

            createCategoryView
                //.opacity(isNameFieldFocused ? 0 : 1)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .task {
            Task {
                do {
                    try await viewModel.loadCategories()
                } catch {
                    assertionFailure("Couldn't load categories")
                }
            }
        }
        .fullScreenCover(isPresented: $showingMarkerPicker) {
            MarkerListView(selected: $createdCategoryIcon)
        }
        //.toolbar {
        //    ToolbarItemGroup(placement: .keyboard) {
        //        createCategoryView
        //    }
        //}
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 6) {
            Text("category_selector.header")
                .textStyle(.bodySemibold)
            Text("category_selector.hint")
                .textStyle(.caption, color: .textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - List
    private var listView: some View {
        VStack(spacing: 0) {
            row(name: String(localized: "category_selector.none"),
                isSelected: place.category == nil) {
                noCategoryTile
            } action: {
                place.category = nil
                dismiss()
            }

            ForEach(viewModel.categories) { category in
                rowDivider
                row(name: category.name,
                    isSelected: place.category?.id == category.id) {
                    groupTile(category)
                } action: {
                    place.category = category
                    dismiss()
                }
            }
        }
        .background(.surface1, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.fieldBorder, lineWidth: 1)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color(rgba: "#EEE5D5"))
            .frame(height: 1)
            .padding(.leading, 59)
    }

    @ViewBuilder
    private func row<Tile: View>(name: String,
                                 isSelected: Bool,
                                 @ViewBuilder tile: () -> Tile,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                tile()
                Text(name)
                    .textStyle(isSelected ? .bodySemibold : .body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.dropinPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(isSelected ? Color.dropinPrimary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var noCategoryTile: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(.backgroundTertiary)
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
    }

    private func groupTile(_ category: CategoryUIModel) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(category.color)
            .frame(width: 30, height: 30)
            .overlay {
                IconView(icon: category.icon)
                    .sizeCallout()
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Create bar
    private var createCategoryView: some View {
        HStack(spacing: 10) {
            // Color picker
            ZStack {
                ColorPicker(String(""),
                            selection: $createdCategoryColor,
                            supportsOpacity: false)
                    .labelsHidden()
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(createdCategoryColor)
                    .allowsHitTesting(false)
            }
            .frame(width: 38, height: 38)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }

            // Marker picker
            ZStack {
                if let icon = createdCategoryIcon {
                    IconView(icon: icon)
                        .sizeCallout()
                        .foregroundStyle(.dropinPrimary)
                } else {
                    Image(systemName: "tag")
                        .foregroundStyle(markerPlaceholderColor)
                        .font(markerPlaceholderFont)
                        .opacity(markerPlaceholderOpacity)
                }
            }
            .frame(width: 38, height: 38)
            .background(.surface1, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).stroke(.fieldBorder, lineWidth: 1)
            }
            .opacity(markerCircleOpacity)
            .onTapGesture {
                showingMarkerPicker.toggle()
            }

            // Category name
            TextField("category_selector.new", text: $createdCategoryName)
                .textStyle(.body)
                .autocorrectionDisabled()
                .focused($isNameFieldFocused)
                .overlay {
                    if isShowingNameWarn {
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.surface2)
                            Text("placeholder.category_name")
                                .textStyle(.bodyError)
                        }
                    }
                }
            
            MainSmallButton(text: "common.add", action: createCategory)
                .disabled(createdCategoryName.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.surface2)
        .overlay(alignment: .top) {
            Rectangle().fill(.fieldBorder).frame(height: 1)
        }
    }

    // MARK: - private methods
    private func createCategory() {
        guard let groupIcon = createdCategoryIcon else {
            withAnimation(.linear(duration: 0.25)) {
                markerCircleOpacity = 0
                markerPlaceholderColor = .warning
                markerPlaceholderFont = .system(size: 22)
                markerPlaceholderOpacity = 1
            } completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        markerCircleOpacity = 1
                        markerPlaceholderOpacity = markerPlaceholderOpacityDefault
                        markerPlaceholderColor = markerPlaceholderColorDefault
                        markerPlaceholderFont = markerPlaceholderFontDefault
                    }
                }
            }
            return
        }
        guard !createdCategoryName.isEmpty else {
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
            let newCategory = try await viewModel.createCategory(name: createdCategoryName,
                                                           color: createdCategoryColor.hex,
                                                           icon: groupIcon)
            place.category = newCategory
            createdCategoryName = ""
            createdCategoryColor = Color.random()
            createdCategoryIcon = nil
            dismiss()
        }
    }
}

#if DEBUG
struct MockCategorySelectorView: View {
    var mock: MockContainer
    @State var place: PlaceUIModel
    @State var present: Bool = false

    var body: some View {
        MainButton(text: "go") {
            present.toggle()
        }
        .padding()
        .sheet(isPresented: $present) {
            mock.appContainer.createCategorySelectorView(place: $place)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUIModel(0)
    }
}

#Preview {
    MockCategorySelectorView()
}

#endif
