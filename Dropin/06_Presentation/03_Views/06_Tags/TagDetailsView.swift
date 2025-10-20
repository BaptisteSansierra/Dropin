//
//  TagDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/9/25.
//

import SwiftUI

struct TagDetailsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: TagDetailsViewModel
    @Binding private var tag: TagUI
    @State private var tagColor: Color
    @State private var showingRemoveAlert: Bool = false

    // MARK: - Env
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: TagDetailsViewModel, tag: Binding<TagUI>) {
        self.viewModel = viewModel
        self._tag = tag
        self._tagColor = State(initialValue: tag.wrappedValue.color)
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                TagView(name: tag.name, color: tag.color)
                Spacer()
            }
            .padding(.top, 15)
            .padding(.bottom, 20)

            nameView

            colorView
            
            placesView

            Spacer()
            
            deleteButton
        }
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .alert("alert.remove_tag_title",
               isPresented: $showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteTag(tag)
                        dismiss()
                    } catch {
                        print("Could not delete tag \(tag.name): \(error)")
                    }
                }
            }
        } message: {
            if tag.places.count > 0 {
                Text("alert.remove_tag_body_\(tag.name)_\(tag.places.count)")
            } else {
                Text("alert.remove_tag_empty_body_\(tag.name)")
            }
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.tag_name")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.leading, 40)
                .foregroundStyle(.gray)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.white)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                TextField("common.tag_name", text: $tag.name)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 40)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        updateTag()
                    }
            }
        }
    }
    
    private var colorView: some View {
        VStack(alignment: .leading) {
            Text("common.tag_color")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.leading, 40)
                .padding(.top, 10)
                .foregroundStyle(.gray)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.white)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                HStack() {
                    RoundedRectangle(cornerSize: 8)
                        .frame(height: 25)
                        .frame(width: 100)
                        .foregroundStyle(tagColor)
                        .padding(.leading, 40)
                        //.padding(.trailing, 40)
                    Spacer()
                    ColorPicker("", selection: $tagColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: tagColor) { oldValue, newValue in
                            tag.color = tagColor
                            updateTag()
                        }
                }
            }
        }
    }

    private var placesView: some View {
        VStack(alignment: .leading) {
            
            if tag.places.count > 0 {
                Text("common.related_places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 40)
                    .padding(.top, 30)
                    .foregroundStyle(.gray)
                Divider()
                List {
                    ForEach(tag.places) { place in
                        PlaceRowView(place: place)
                        .swipeActions(allowsFullSwipe: false) {
                            Button() {
                                guard let idx = tag.places.firstIndex(where: { place.id == $0.id }) else { return }
                                tag.places.remove(at: idx)
                                updateTag()
                            } label: {
                                Text("common.unlink")
                            }
                            .tint(.red)
                        }
                    }
                }
            } else {
                Text("common.no_related_places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 40)
                    .padding(.top, 30)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private var deleteButton: some View {
        ZStack {
            RoundedRectangle(cornerSize: 8)
                .foregroundStyle(.red)
                .frame(width: DropinApp.ui.button.width,
                       height: DropinApp.ui.button.height)
            Text("common.delete_tag")
                .foregroundStyle(.white)
        }
        .padding(.bottom, 15)
        .onTapGesture {
            showingRemoveAlert = true
        }
    }
    
    // MARK: private methods
    private func updateTag() {
        Task {
            do {
                try await viewModel.updateTag(tag)
            } catch {
                // TODO: handle error
                assertionFailure("Could not update tag: \(error)")
            }
        }
    }
}


#if DEBUG

struct MockTagDetailsView: View {
    var mock: MockContainer
    @State private var tag: TagUI

    var body: some View {
        mock.appContainer.createTagDetailsView(tag: $tag)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.tag = mock.getTagUI(0)
    }
}

#Preview {
    NavigationStack {
        MockTagDetailsView()
            .environment(NavigationContext())
            .environment(LocationManager())
    }
}

#endif
