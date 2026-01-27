//
//  MarkerListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI

struct MarkerListView: View {
    
    // MARK: - State & Bindings
    @State private var position = ScrollPosition(edge: .bottom)
    @State private var confirmed = false
    @Binding private var selected: Icon?
    @State private var nullable: Bool

    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    
    // MARK: - private properties
    private let columns = [GridItem(.adaptive(minimum: 60))]

    // MARK: - Init
    init(selected: Binding<Icon?>) {
        self._selected = selected
        self.nullable = true
    }
    
    init(selected: Binding<Icon>) {
        self._selected = Binding(get: {
            selected.wrappedValue
        }, set: { value in
            selected.wrappedValue = value ?? selected.wrappedValue
        })
        self.nullable = false
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerView
                scrollView
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: nullable ? 60 : 0)
                    }
            }
            if nullable && selected != nil {
                footerView
            }
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        ZStack {
            Text("markers.select")
                .textStyle(.body)
                .padding()
            HStack {
                Spacer()
                Button("", systemImage: "xmark.circle") {
                    dismiss()
                }
                .padding()
                .tint(.dropinPrimary)
            }
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack() {
                    ForEach(IconLibrary.categories, id: \.self.nameKey) { categoryItem in
                        Section {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(categoryItem.icons, id: \.self) { icon in
                                    let isSelected = icon == selected
                                    ZStack {
                                        Circle()
                                            .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 3))
                                            .frame(width: 38, height: 38)
                                            .opacity(isSelected ? 0.5 : 0)
                                        Circle()
                                            .foregroundStyle(.dropinPrimary)
                                            .frame(width: 33, height: 33)
                                            .opacity(isSelected ? 1 : 0)
                                        IconView(icon: icon)
                                            .sizeCaption()
                                            .foregroundStyle(isSelected ? .backgroundPrimary : .textTertiary)
                                            .onTapGesture {
                                                selected = icon
                                                dismiss()
                                            }
                                            .id(icon.id)
                                    }
                                    .frame(minHeight: 30)
                                }
                            }
                            .padding(.vertical, 10)
                            .background(.backgroundPrimary)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                        } header: {
                            Text(LocalizedStringKey(categoryItem.nameKey))
                                .textStyle(.formSectionTitle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textCase(.uppercase)
                                .padding(.horizontal, 30)
                                .padding(.top)
                        }
                    }
                }
                .onAppear {
                    if let selected = selected {
                        proxy.scrollTo(selected.id, anchor: .center)
                    }
                }
            }
        }
        .background(.backgroundSecondary)
    }
    
    private var footerView: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Rectangle()
                    .ignoresSafeArea()
                    .foregroundStyle(.clear)
                    .background(.ultraThinMaterial)
                    .frame(height: 60)
                Button("common.clear_selection") {
                    selected = nil
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG

struct MockMarkerListSelectionView: View {
    @Binding var icon: Icon?
    var body: some View {
        HStack {
            if let icon = icon {
                Text(verbatim: "common.selected")
                IconView(icon: icon)
                    .sizeCaption2()
                Text(icon.rawValue)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            } else {
                Text(verbatim: "common.no_item_selected")
            }
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerSize: 8)
                .strokeBorder(.pink, style: StrokeStyle(lineWidth: 4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    
    init(icon: Binding<Icon?>) {
        self._icon = icon
    }

    init(icon: Binding<Icon>) {
        self._icon = Binding(
            get: { icon.wrappedValue },
            set: { icon.wrappedValue = $0 ?? icon.wrappedValue }
        )
    }
}

struct MockNullableMarkerListView: View {
    @State var icon: Icon? = .sf("figure.socialdance") // "figure.outdoor.rowing"
    var body: some View {
        VStack {
            MockMarkerListSelectionView(icon: $icon)
                .background(.orange.opacity(0.2))
            Divider()
            MarkerListView(selected: $icon)
        }
    }
}

struct MockMarkerListView: View {
    @State var icon: Icon = .sf("figure.socialdance")
    var body: some View {
        MockMarkerListSelectionView(icon: $icon)
            .background(.purple.opacity(0.2))
        Divider()
        MarkerListView(selected: $icon)
    }
}

#Preview {
    VStack {
        MockMarkerListView()
    }
}

#Preview {
    VStack {
        MockNullableMarkerListView()
    }
}

#endif
