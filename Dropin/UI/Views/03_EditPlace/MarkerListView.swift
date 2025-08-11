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
    @Binding private var selected: String
    
    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    
    // MARK: - private vars
    private var oldValue: String
    private var sections: [(name: String, items: [String])] = [
        ("Food", ["fork.knife.circle",
                  "carrot",
                  "birthday.cake",
                  "cup.and.saucer",
                  "wineglass",
                  "mug"]),
        ("Shop", ["basket",
                  "cart",
                  "car",
                  "creditcard",
                  "gamecontroller",
                  "pill",
                  "text.book.closed",
                  "magazine"]),
        ("Fun", ["music.note",
                 "pianokeys",
                 "figure.socialdance",
                ]),
        ("Sport", ["basketball",
                   "american.football",
                   "tennisball",
                   "soccerball",
                   "volleyball",
                   "skateboard",
                   "snowboard",
                   "surfboard",
                   "figure.run",
                   "figure.run.treadmill",
                   "sportscourt",
                   //"figure.volleyball",
                   //"figure.basketball",
                   "figure.racquetball",
                   //"figure.australian.football",
                   //"figure.baseball",
                   "figure.open.water.swim",
                   //"figure.barre",
                   "figure.bowling",
                   "figure.climbing",
                   "figure.cooldown",
                   //"figure.core.training",
                   //"figure.dance",
                   "figure.fishing",
                   "figure.golf",
                   "figure.hiking",
                   "figure.hunting",
                   "figure.mind.and.body",
                   "figure.outdoor.cycle",
                   "figure.outdoor.rowing",
                   "figure.sailing",
                   "figure.skateboarding"
                  ]),
        ("Misc", ["tag",
                  "star",
                  "star.square",
                  "moon.stars",
                  "staroflife.fill",
                  "giftcard",
                  "graduationcap",
                  "backpack",
                  "paperclip",
                  "photo.artframe",
                  "figure.roll",
                  "peacesign"])
    ]
    private let columns = [GridItem(.adaptive(minimum: 60))]
    
    // MARK: - Body
    var body: some View {
        VStack {
            headerView
            listView
        }
        .onAppear() {
            // TODO: scroll on selected
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        ZStack {
            Text("Select a marker")
                .padding()
            HStack {
                Spacer()
                Button("", systemImage: "xmark.circle") {
                    selected = oldValue
                    dismiss()
                }
                .padding()
                .tint(.dropinPrimary)
            }
        }
    }
    
    private var listView: some View {
        List {
            ForEach(sections, id: \.self.name) { section in
                Section(section.name) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(section.items, id: \.self) { item in
                            let isSelected = item == selected
                            ZStack {
                                Image(systemName: item)
                                    .foregroundStyle(isSelected ? .black : .gray)
                                    .onTapGesture {
                                        selected = item
                                        dismiss()
                                    }
                                    .id(item)
                                Circle()
                                    .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 3))
                                    .frame(width: 30, height: 30)
                                    .opacity(isSelected ? 1 : 0)
                            }
                            .frame(minHeight: 30)
                        }
                    }
                }
            }
        }
    }
    
    init(selected: Binding<String>) {
        self._selected = selected
        self.oldValue = selected.wrappedValue
    }
}

#Preview {
    @Previewable @State var marker: String  = "carrot"
    MarkerListView(selected: $marker)
}
