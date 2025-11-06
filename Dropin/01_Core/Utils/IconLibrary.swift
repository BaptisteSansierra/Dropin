//
//  IconLibrary.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/11/25.
//

import Foundation

struct IconLibrary {
    
    static let categories: [(name: String, icons: [Icon])] = [
        // TODO : L10N category names
        ("Food & Drinks", [
            // Food
            Icon(source: .sf, name: "fork.knife"),
            Icon(source: .fa, name: "pizza-slice"),
            Icon(source: .fa, name: "burger"),
            Icon(source: .fa, name: "bowl-rice"),
            Icon(source: .sf, name: "birthday.cake"),
            Icon(source: .fa, name: "ice-cream"),
            Icon(source: .sf, name: "carrot"),
            Icon(source: .sf, name: "takeoutbag.and.cup.and.straw"),   // Fast-food/Takeout
            // Drinks
            Icon(source: .sf, name: "cup.and.saucer"),
            Icon(source: .fa, name: "beer-mug-empty"),
            Icon(source: .sf, name: "wineglass"),
            Icon(source: .fa, name: "martini-glass-citrus"),
            Icon(source: .sf, name: "waterbottle"),
            ]),
        
        ("Entertainment", [
            Icon(source: .sf, name: "music.note"),
            Icon(source: .sf, name: "pianokeys"),
            Icon(source: .fa, name: "microphone"),
            Icon(source: .sf, name: "figure.socialdance"),
            Icon(source: .fa, name: "bowling-ball"),
            Icon(source: .sf, name: "film"),
            Icon(source: .fa, name: "masks-theater"),
            Icon(source: .sf, name: "gamecontroller"),
            Icon(source: .sf, name: "dice"),
            Icon(source: .sf, name: "opticaldisc"),
            ]),

        ("Services", [
            Icon(source: .sf, name: "cross.case"),               // medic
            Icon(source: .sf, name: "stethoscope"),              // medic
            Icon(source: .fa, name: "spa"),                      // spa
            Icon(source: .sf, name: "scissors"),                 // Coiffeur/Barbier
            Icon(source: .fa, name: "paw"),                      // animals
            Icon(source: .sf, name: "wrench.and.screwdriver"),   // Réparation/Bricolage
            Icon(source: .sf, name: "banknote"),
            Icon(source: .sf, name: "envelope"),                 // Poste
            Icon(source: .sf, name: "fuelpump"),                 // Gas station
            Icon(source: .sf, name: "parkingsign.circle"),       // Parking
            ]),

        ("Shopping", [
            Icon(source: .sf, name: "cart"),                   // Supermarché
            Icon(source: .sf, name: "basket"),                 // Épicerie/Marché
            Icon(source: .sf, name: "bag"),                    // Shopping général
            Icon(source: .sf, name: "tshirt"),                 // Vêtements
            Icon(source: .sf, name: "eyeglasses"),             // Optique
            Icon(source: .sf, name: "camera"),                 // Photo/Électronique
            Icon(source: .sf, name: "magazine"),               // Librairie/Presse
            Icon(source: .sf, name: "text.book.closed"),       // Bibliothèque
            Icon(source: .sf, name: "bag"),                    // Centre commercial
        ]),

        ("Sports & Fitness", [
               // Ball sports
            Icon(source: .sf, name: "basketball"),
            Icon(source: .sf, name: "soccerball"),
            Icon(source: .sf, name: "tennisball"),
            Icon(source: .sf, name: "volleyball"),
            Icon(source: .sf, name: "american.football"),
               
               // Activities
            Icon(source: .sf, name: "figure.walk"),
            Icon(source: .sf, name: "figure.run"),             // Running/Jogging
               
            Icon(source: .sf, name: "figure.outdoor.cycle"),   // Vélo
            Icon(source: .sf, name: "figure.open.water.swim"), // Piscine/Natation
            Icon(source: .sf, name: "figure.yoga"),            // Yoga/Pilates
            Icon(source: .sf, name: "figure.strengthtraining.traditional"), // Gym/Musculation
            Icon(source: .sf, name: "figure.climbing"),        // Escalade
            Icon(source: .sf, name: "figure.hiking"),          // Randonnée
            Icon(source: .sf, name: "figure.skating"),         // Patinage
            Icon(source: .sf, name: "figure.mind.and.body"),
            Icon(source: .sf, name: "figure.play"),
               
               // Equipment
            Icon(source: .sf, name: "dumbbell"),               // Fitness
            Icon(source: .sf, name: "sportscourt"),            // Terrain de sport
           ]),
           
        ("Nature & Outdoors", [
            Icon(source: .sf, name: "tree"),                   // Parc/Forêt
            Icon(source: .sf, name: "leaf"),                   // Jardin
            Icon(source: .sf, name: "mountain.2"),             // Montagne
            Icon(source: .sf, name: "water.waves"),            // Plage/Lac
            Icon(source: .sf, name: "sunrise"),                // Point de vue
            Icon(source: .sf, name: "tent"),                   // Camping
            Icon(source: .sf, name: "figure.fishing"),         // Pêche
           ]),
           
        ("Culture & Education", [
            Icon(source: .sf, name: "building.columns"),       // Musée/Monument
            Icon(source: .sf, name: "photo.artframe"),         // Galerie d'art
            Icon(source: .sf, name: "graduationcap"),          // École/Université
            Icon(source: .sf, name: "book"),                   // Bibliothèque
            Icon(source: .sf, name: "building.2"),             // Lieu historique
            Icon(source: .sf, name: "info.circle"),            // Office de tourisme
            Icon(source: .fa, name: "book"),                   //
            Icon(source: .fa, name: "palette"),                //
           ]),
                   
        ("Transport", [
            Icon(source: .sf, name: "car"),                    // Location voiture
            Icon(source: .sf, name: "bus"),                    // Arrêt de bus
            Icon(source: .sf, name: "tram"),                   // Tramway
            Icon(source: .sf, name: "train.side.front.car"),   // Gare
            Icon(source: .sf, name: "airplane"),               // Aéroport
            Icon(source: .sf, name: "ferry"),                  // Ferry/Bateau
            Icon(source: .sf, name: "bicycle"),                // Vélo location
           ]),
           
        ("Accommodation", [
            Icon(source: .sf, name: "bed.double"),             // Hôtel
            Icon(source: .sf, name: "house"),                  // Maison/AirBnB
            Icon(source: .sf, name: "building"),               // Appartement
            Icon(source: .sf, name: "tent.2"),                 // Camping/Glamping
            Icon(source: .sf, name: "figure.roll"),            // Accessibility
           ]),
           
        ("Special", [
            Icon(source: .sf, name: "star"),                   // Favori/Important
            Icon(source: .sf, name: "heart"),                  // Coup de cœur
            Icon(source: .sf, name: "flag"),                   // À visiter
            Icon(source: .sf, name: "mappin.and.ellipse"),     // Rendez-vous
            Icon(source: .sf, name: "clock"),                  // Temporaire/Événement
            Icon(source: .sf, name: "gift"),                   // Cadeau/Surprise
            Icon(source: .sf, name: "exclamationmark.triangle"), // Attention/Important
            Icon(source: .sf, name: "checkmark.circle"),       // Validé/Testé
            Icon(source: .sf, name: "peacesign"),
            Icon(source: .sf, name: "swirl.circle.righthalf.filled.inverse"),
            Icon(source: .sf, name: "paperclip")
           ])
    ]
}
