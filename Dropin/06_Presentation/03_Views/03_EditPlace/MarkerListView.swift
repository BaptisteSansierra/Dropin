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
    @Binding private var selected: String?
    @State private var nullable: Bool

    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    
    // MARK: - private properties
    private var sections: [(name: String, items: [String])] = [
        ("Food & Drinks", [
            // Meals
            "fork.knife.circle",      // Général restaurant
            "takeoutbag.and.cup.and.straw", // Fast-food/Takeout
            "birthday.cake",          // Pâtisserie/Desserts
            "carrot",                 // Végétarien/Healthy
            
            // Drinks
            "cup.and.saucer",         // Café
            "mug",                    // Bar/Pub
            "wineglass",              // Bar à vin/Cocktails
            "waterbottle",            // Juice bar/Smoothies
        ]),
        
        ("Shopping", [
            "cart",                   // Supermarché
            "basket",                 // Épicerie/Marché
            "bag",                    // Shopping général
            "tshirt",                 // Vêtements
            "eyeglasses",             // Optique
            "camera",                 // Photo/Électronique
            "magazine",               // Librairie/Presse
            "text.book.closed",       // Bibliothèque
            "bag.circle",             // Centre commercial
        ]),
        
        ("Entertainment", [
            "music.note",             // Concert/Musique live
            "pianokeys",              // Piano bar
            "figure.socialdance",     // Club/Danse
            "theatermasks",           // Théâtre
            "film",                   // Cinéma
            "gamecontroller",         // Gaming/Arcade
            "dice",                   // Jeux de société
            "opticaldisc"
        ]),
        
        ("Sports & Fitness", [
            // Ball sports
            "basketball",
            "soccerball",
            "tennisball",
            "volleyball",
            "american.football",
            
            // Activities
            "figure.walk",
            "figure.run",             // Running/Jogging
            "figure.outdoor.cycle",   // Vélo
            "figure.open.water.swim", // Piscine/Natation
            "figure.yoga",            // Yoga/Pilates
            "figure.strengthtraining.traditional", // Gym/Musculation
            "figure.climbing",        // Escalade
            "figure.hiking",          // Randonnée
            "figure.skating",         // Patinage
            "figure.mind.and.body",
            "figure.play",
            
            // Equipment
            "dumbbell",               // Fitness
            "sportscourt",            // Terrain de sport
        ]),
        
        ("Nature & Outdoors", [
            "tree",                   // Parc/Forêt
            "leaf",                   // Jardin
            "mountain.2",             // Montagne
            "water.waves",            // Plage/Lac
            "sunrise",                // Point de vue
            "tent",                   // Camping
            "figure.fishing",         // Pêche
        ]),
        
        ("Culture & Education", [
            "building.columns",       // Musée/Monument
            "photo.artframe",         // Galerie d'art
            "graduationcap",          // École/Université
            "book",                   // Bibliothèque
            "building.2",             // Lieu historique
            "info.circle",            // Office de tourisme
        ]),
        
        ("Services", [
            "cross.case",             // Pharmacie/Médical
            "stethoscope",            // Médecin/Clinique
            "scissors",               // Coiffeur/Barbier
            "wrench.and.screwdriver", // Réparation/Bricolage
            "banknote",               // Banque/ATM
            "envelope",               // Poste
            "fuelpump",               // Station-service
            "parkingsign.circle",     // Parking
        ]),
        
        ("Transport", [
            "car",                    // Location voiture
            "bus",                    // Arrêt de bus
            "tram",                   // Tramway
            "train.side.front.car",   // Gare
            "airplane",               // Aéroport
            "ferry",                  // Ferry/Bateau
            "bicycle",                // Vélo location
        ]),
        
        ("Accommodation", [
            "bed.double",             // Hôtel
            "house",                  // Maison/AirBnB
            "building",               // Appartement
            "tent.2",                 // Camping/Glamping
            "figure.roll",            // Accessibility
        ]),
        
        ("Special", [
            "star",                   // Favori/Important
            "heart",                  // Coup de cœur
            "flag",                   // À visiter
            "mappin.and.ellipse",     // Rendez-vous
            "clock",                  // Temporaire/Événement
            "gift",                   // Cadeau/Surprise
            "exclamationmark.triangle", // Attention/Important
            "checkmark.circle",       // Validé/Testé
            "peacesign",
            "swirl.circle.righthalf.filled.inverse",
            "paperclip",
            "tag"
        ])
    ]
    
    /*
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
                  "peacesign",
                  "swirl.circle.righthalf.filled.inverse"])
    ]
     */
    private let columns = [GridItem(.adaptive(minimum: 60))]

    // MARK: - Init
    init(selected: Binding<String?>) {
        self._selected = selected
        self.nullable = true
    }
    
    init(selected: Binding<String>) {
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
                    ForEach(sections, id: \.self.name) { section in
                        Section {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(section.items, id: \.self) { item in
                                    let isSelected = item == selected
                                    ZStack {
                                        Circle()
                                            .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 3))
                                            .frame(width: 38, height: 38)
                                            .opacity(isSelected ? 0.5 : 0)
                                        Circle()
                                            .foregroundStyle(.dropinPrimary)
                                            .frame(width: 33, height: 33)
                                            .opacity(isSelected ? 1 : 0)
                                        Image(systemName: item)
                                            .foregroundStyle(isSelected ? .white : .gray)
                                            .onTapGesture {
                                                selected = item
                                                dismiss()
                                            }
                                            .id(item)
                                    }
                                    .frame(minHeight: 30)
                                }
                            }
                            .padding(.vertical, 10)
                            .background(.white)
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                        } header: {
                            Text(section.name)
                                .font(.headline)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textCase(.uppercase)
                                .padding(.horizontal, 30)
                                .padding(.top)
                        }
                    }
                }
                .onAppear {
                    if let selected = selected {
                        proxy.scrollTo(selected, anchor: .center)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
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
    @Binding var marker: String?
    var body: some View {
        HStack {
            if let marker = marker {
                Text(verbatim: "common.selected")
                Image(systemName: marker)
                Text(marker)
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                Text(verbatim: "common.no_item_selected")
            }
        }
        .padding()
        .overlay {
            RoundedRectangle(cornerSize: 8)
                .strokeBorder(.red, style: StrokeStyle(lineWidth: 4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    
    init(marker: Binding<String?>) {
        self._marker = marker
    }

    init(marker: Binding<String>) {
        self._marker = Binding(
            get: { marker.wrappedValue },
            set: { marker.wrappedValue = $0 ?? marker.wrappedValue }
        )
    }
}

struct MockNullableMarkerListView: View {
    @State var marker: String? = "figure.socialdance" // "figure.outdoor.rowing"
    var body: some View {
        VStack {
            MockMarkerListSelectionView(marker: $marker)
                .background(.orange.opacity(0.2))
            Divider()
            MarkerListView(selected: $marker)
        }
    }
}

struct MockMarkerListView: View {
    @State var marker: String = "figure.socialdance"
    var body: some View {
        MockMarkerListSelectionView(marker: $marker)
            .background(.purple.opacity(0.2))
        Divider()
        MarkerListView(selected: $marker)
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
