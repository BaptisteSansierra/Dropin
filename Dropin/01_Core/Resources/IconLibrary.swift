//
//  IconLibrary.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/11/25.
//

import SwiftUI

struct IconLibrary {

    static let categories: [(nameKey: String, icons: [Icon])] = [
        ("category.food_drinks", [
            // Food
            .sf("fork.knife"),
            .fa("pizza-slice"),
            .fa("burger"),
            .fa("bowl-rice"),
            .sf("birthday.cake"),
            .fa("ice-cream"),
            .sf("carrot"),
            .sf("takeoutbag.and.cup.and.straw"),   // Fast-food/Takeout
            // Drinks
            .sf("cup.and.saucer"),
            .fa("beer-mug-empty"),
            .sf("wineglass"),
            .fa("martini-glass-citrus"),
            .sf("waterbottle"),
            ]),
        
        ("category.entertainment", [
            .sf("music.note"),
            .sf("pianokeys"),
            .fa("microphone"),
            .sf("figure.socialdance"),
            .fa("bowling-ball"),
            .sf("film"),
            .fa("masks-theater"),
            .sf("gamecontroller"),
            .sf("dice"),
            .sf("opticaldisc"),
            ]),

        ("category.services", [
            .sf("cross.case"),               // medic
            .sf("stethoscope"),              // medic
            .fa("spa"),                      // spa
            .sf("scissors"),                 // Coiffeur/Barbier
            .fa("paw"),                      // animals
            .sf("wrench.and.screwdriver"),   // Réparation/Bricolage
            .sf("banknote"),
            .sf("envelope"),                 // Poste
            .sf("fuelpump"),                 // Gas station
            .sf("parkingsign.circle"),       // Parking
            ]),

        ("category.shopping", [
            .sf("cart"),                   // Supermarché
            .sf("basket"),                 // Épicerie/Marché
            .sf("bag"),                    // Shopping général
            .sf("tshirt"),                 // Vêtements
            .sf("eyeglasses"),             // Optique
            .sf("camera"),                 // Photo/Électronique
            .sf("magazine"),               // Librairie/Presse
            .sf("text.book.closed"),       // Bibliothèque
            .sf("bag"),                    // Centre commercial
        ]),

        ("category.sports", [
               // Ball sports
            .sf("basketball"),
            .sf("soccerball"),
            .sf("tennisball"),
            .sf("volleyball"),
            .sf("american.football"),
               
               // Activities
            .sf("figure.walk"),
            .sf("figure.run"),             // Running/Jogging
               
            .sf("figure.outdoor.cycle"),   // Vélo
            .sf("figure.open.water.swim"), // Piscine/Natation
            .sf("figure.yoga"),            // Yoga/Pilates
            .sf("figure.strengthtraining.traditional"), // Gym/Musculation
            .sf("figure.climbing"),        // Escalade
            .sf("figure.hiking"),          // Randonnée
            .sf("figure.skating"),         // Patinage
            .sf("figure.mind.and.body"),
            .sf("figure.play"),
               
               // Equipment
            .sf("dumbbell"),               // Fitness
            .sf("sportscourt"),            // Terrain de sport
           ]),
           
        ("category.nature", [
            .sf("tree"),                   // Parc/Forêt
            .sf("leaf"),                   // Jardin
            .sf("mountain.2"),             // Montagne
            .sf("water.waves"),            // Plage/Lac
            .sf("sunrise"),                // Point de vue
            .sf("tent"),                   // Camping
            .sf("figure.fishing"),         // Pêche
           ]),
           
        ("category.education", [
            .sf("building.columns"),       // Musée/Monument
            .sf("photo.artframe"),         // Galerie d'art
            .sf("graduationcap"),          // École/Université
            .sf("book"),                   // Bibliothèque
            .sf("building.2"),             // Lieu historique
            .sf("info.circle"),            // Office de tourisme
            .fa("book"),                   //
            .fa("palette"),                //
           ]),

        ("category.people", [
            .sf("figure.2.and.child.holdinghands"),  // Famille avec enfants
            .sf("figure.and.child.holdinghands"),     // Parent-enfant
            .sf("house.and.flag"),                    // Maison familiale
            .sf("figure.2"),                          // Couple (2 personnes)
            .sf("person.2.fill"),                     // Amis (2 personnes)
            .sf("person.3.fill"),                     // Groupe d'amis
            .sf("person.2.wave.2"),                   // Amis qui se saluent
            .sf("bubble.left.and.bubble.right"),      // Conversation
            .sf("person.text.rectangle"),             // Collègue
            .sf("person.fill"),                       // Personne générique
        ]),
        
        ("category.transport", [
            .sf("car"),                    // Location voiture
            .sf("bus"),                    // Arrêt de bus
            .sf("tram"),                   // Tramway
            .sf("train.side.front.car"),   // Gare
            .sf("airplane"),               // Aéroport
            .sf("ferry"),                  // Ferry/Bateau
            .sf("bicycle"),                // Vélo location
           ]),
           
        ("category.accommodation", [
            .sf("bed.double"),             // Hôtel
            .sf("house"),                  // Maison/AirBnB
            .sf("building"),               // Appartement
            .sf("tent.2"),                 // Camping/Glamping
            .sf("figure.roll"),            // Accessibility
           ]),
           
        ("category.special", [
            .sf("star"),                   // Favori/Important
            .sf("heart"),                  // Coup de cœur
            .sf("flag"),                   // À visiter
            .sf("mappin.and.ellipse"),     // Rendez-vous
            .sf("clock"),                  // Temporaire/Événement
            .sf("gift"),                   // Cadeau/Surprise
            .sf("exclamationmark.triangle"), // Attention/Important
            .sf("checkmark.circle"),       // Validé/Testé
            .sf("peacesign"),
            .sf("swirl.circle.righthalf.filled.inverse"),
            .sf("paperclip")
           ])
    ]
}
