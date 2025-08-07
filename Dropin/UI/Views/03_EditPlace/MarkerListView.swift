//
//  MarkerListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI

@Observable class MarkerListModelView {
    static var defaultSystemImage = "tag"
    var selected: String
    
    init(selected: String? = nil) {
        self.selected = MarkerListModelView.defaultSystemImage
    }
    
    func reset() {
        self.selected = MarkerListModelView.defaultSystemImage
    }
}

struct MarkerListView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(MarkerListModelView.self) private var modelView
    
    @State private var position = ScrollPosition(edge: .bottom)

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
    
    var body: some View {
        VStack {
            ZStack {
                Text("Select a marker")
                    .padding()
                HStack {
                    Spacer()
                    Button("", systemImage: "xmark.circle") {
                        modelView.selected = "tag"
                        dismiss()
                    }
                    .padding()
                    .tint(.dropinPrimary)
                }
            }
            List {
                ForEach(sections, id: \.self.name) { section in
                    Section(section.name) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(section.items, id: \.self) { item in
                                let isSelected = item == modelView.selected
                                ZStack {
                                    Image(systemName: item)
                                        .foregroundStyle(isSelected ? .black : .gray)
                                        .onTapGesture {
                                            modelView.selected = item
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
            //.scrollPosition($position)
        }
        .onAppear() {
            // TODO: scroll on selected 
            //position.scrollTo(id: modelView.selected)
        }
    }
}

#Preview {
    MarkerListView()
        .environment(MarkerListModelView())
}
