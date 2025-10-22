//
//  GroupDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/9/25.
//

import SwiftUI

struct GroupDetailsView: View {
    
    // MARK: - State & Bindings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var group: SDGroup
    @State private var groupColor: Color
    @State private var showingRemoveAlert: Bool = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                GroupView(name: group.name, color: Color(rgba: group.color), hasDestructiveBt: false)
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
        .alert("alert.remove_group_title",
               isPresented: $showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                modelContext.delete(group)
                dismiss()
            }
        } message: {
            if group.places.count > 0 {
                Text("alert.remove_group_body_\(group.name)_\(group.places.count)")
            } else {
                Text("alert.remove_group_empty_body_\(group.name)")
            }
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.group_name")
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
                TextField("common.group_name", text: $group.name)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 40)
                    .autocorrectionDisabled()
            }
        }
    }
    
    private var colorView: some View {
        VStack(alignment: .leading) {
            Text("common.group_color")
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
                        .foregroundStyle(groupColor)
                        .padding(.leading, 40)
                        //.padding(.trailing, 40)
                    Spacer()
                    ColorPicker("", selection: $groupColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: groupColor) { oldValue, newValue in
                            group.color = groupColor.hex
                        }

                }
            }
        }
    }

    private var placesView: some View {
        VStack(alignment: .leading) {
            if group.places.count > 0 {
                Text("common.related_places")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 40)
                    .padding(.top, 30)
                    .foregroundStyle(.gray)
                Divider()
                List {
                    ForEach(group.places) { place in
                        PlaceRowView(place: place)
                        .swipeActions(allowsFullSwipe: false) {
                            Button() {
                                guard let idx = group.places.firstIndex(of: place) else { return }
                                group.places.remove(at: idx)
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
            Text("common.delete_group")
                .foregroundStyle(.white)
        }
        .padding(.bottom, 15)
        .onTapGesture {
            showingRemoveAlert = true
        }
    }
    
    // MARK: - Init
    init(group: SDGroup) {
        self.group = group // State(initialValue: group)
        self._groupColor = State(initialValue: Color(rgba: group.color))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GroupDetailsView(group: SDGroup.g1)
    }
    .navigationTitle("Pipo")
    .navigationBarTitleDisplayMode(.large)
}
#endif
