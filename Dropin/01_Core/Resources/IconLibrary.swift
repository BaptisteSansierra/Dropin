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
            .fa("bread-slice"),            // Bakery
            .sf("fish"),                   // Seafood
            .fa("cheese"),                 // Cheese/deli
            .fa("drumstick-bite"),         // Butcher
            ]),
        
        ("category.entertainment", [
            .sf("music.note"),
            .sf("pianokeys"),
            //.fa("microphone"),
            .sf("music.mic"),
            .sf("figure.socialdance"),
            //.fa("bowling-ball"),
            .sf("figure.bowling"),
            .sf("film"),
            //.fa("masks-theater"),
            .sf("theatermasks"),
            .sf("gamecontroller"),
            .sf("dice"),
            .sf("opticaldisc"),
            .sf("text.book.closed"),
            .sf("ticket"),                 // Tickets/theme park
            .fa("hippo"),                  // Zoo
            // "fish-fins" rather than .sf("fish") — that's already used for Seafood above.
            .fa("fish-fins"),              // Aquarium
            ]),

        ("category.services", [
            .sf("cross.case"),               // medic
            .sf("stethoscope"),              // medic
            .fa("spa"),                      // spa
            .sf("scissors"),                 // Coiffeur/Barbier
            //.fa("paw"),                      // animals
            .sf("pawprint"),                 // animals
            .sf("wrench.and.screwdriver"),   // Réparation/Bricolage
            .sf("banknote"),
            .sf("envelope"),                 // Poste
            .sf("figure.roll"),              // Accessibility
            .sf("pills"),                    // Pharmacy
            .fa("tooth"),                    // Dentist
            .sf("cross"),                    // Hospital
            .fa("building-shield"),          // Police
            .sf("washer"),                   // Laundry
            .fa("restroom"),                 // Restroom
            .sf("wifi"),                      // Wi-Fi
            .sf("laptopcomputer"),            // Coworking
            .sf("ev.charger"),                // EV charging — double-check this name in the SF Symbols app
            ]),

        ("category.shopping", [
            .sf("cart"),                   // Supermarché
            .sf("basket"),                 // Épicerie/Marché
            .sf("storefront"),             // Shopping général
            .sf("tshirt"),                 // Vêtements
            .sf("eyeglasses"),             // Optique
            .sf("camera"),                 // Photo/Électronique
            .sf("magazine"),               // Librairie/Presse
            .sf("bag"),                    // Centre commercial
            .sf("camera.macro"),           // Florist (tulip-shaped icon)
            .fa("gem"),                    // Jewelry
            .sf("sofa"),                   // Furniture/home
            .sf("hammer"),                 // Hardware
            .sf("desktopcomputer"),        // Electronics
            .sf("puzzlepiece"),            // Toys
            .fa("recycle"),                // Second-hand/vintage
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
            .sf("figure.skiing.downhill"), // Skiing
            .sf("figure.surfing"),         // Surfing
            .sf("figure.golf"),            // Golf
            .sf("figure.equestrian.sports"), // Horse riding
            .sf("figure.martial.arts"),    // Martial arts
            .sf("figure.skateboarding"),   // Skate
            .sf("sailboat"),               // Sailing
           ]),
           
        ("category.nature", [
            .sf("tree"),                   // Parc/Forêt
            .sf("leaf"),                   // Jardin
            .sf("mountain.2"),             // Montagne
            .sf("water.waves"),            // Plage/Lac
            .sf("binoculars"),             // Point de vue (clearer than sunrise)
            .sf("tent"),                   // Camping
            .sf("figure.fishing"),         // Pêche
            .sf("beach.umbrella"),         // Beach
            .sf("snowflake"),              // Snow/ski area
            .fa("volcano"),                // Volcano
            .fa("tower-observation"),      // Lighthouse/tower
           ]),
           
        ("category.education", [
            .sf("building.columns"),       // Musée/Monument
            .sf("photo.artframe"),         // Galerie d'art
            .sf("graduationcap"),          // École/Université
            .sf("books.vertical"),         // Bibliothèque
            .sf("building.2"),             // Lieu historique
            .sf("info.circle"),            // Office de tourisme
            .fa("palette"),                //
            .fa("church"),                 // Church
            .fa("mosque"),                 // Mosque
            .fa("synagogue"),              // Synagogue
            .fa("place-of-worship"),       // Temple
            .fa("torii-gate"),             // Torii (Japan)
            .fa("landmark"),       // Monument
            //.sf("building.columns"),       // Monument
            .fa("chess-rook"),             // Castle
           ]),

        ("category.people", [
            .sf("figure.2.and.child.holdinghands"),  // Famille avec enfants
            .sf("figure.and.child.holdinghands"),     // Parent-enfant
            .sf("house.and.flag"),                    // Maison familiale
            .sf("figure.2"),                          // Couple (2 personnes)
            .sf("person.2"),                     // Amis (2 personnes)
            .sf("person.3"),                     // Groupe d'amis
            .sf("person.2.wave.2"),                   // Amis qui se saluent
            .sf("bubble.left.and.bubble.right"),      // Conversation
            .sf("person.text.rectangle"),             // Collègue
            .sf("person"),                       // Personne générique
            .sf("briefcase"),                    // Work
            .sf("house.fill"),                   // Home (filled, to tell it apart from Accommodation's house)
        ]),
        
        ("category.transport", [
            .sf("car"),                    // Location voiture
            .sf("bus"),                    // Arrêt de bus
            .sf("tram"),                   // Tramway
            .sf("train.side.front.car"),   // Gare
            .sf("airplane"),               // Aéroport
            .sf("ferry"),                  // Ferry/Bateau
            .sf("bicycle"),                // Vélo location
            .sf("fuelpump"),               // Gas station
            .sf("parkingsign.circle"),     // Parking
            .sf("tram.fill.tunnel"),       // Metro
            .fa("taxi"),                   // Taxi
            .sf("scooter"),                // Scooter
            .fa("motorcycle"),             // Motorcycle
            .sf("cablecar"),               // Cable car
            // "anchor" rather than .sf("sailboat") — that's already used for Sailing above.
            .fa("anchor"),                 // Harbour/marina
           ]),
           
        ("category.accommodation", [
            .sf("bed.double"),             // Hôtel
            .sf("house"),                  // Maison/AirBnB
            .sf("building"),               // Appartement
            .sf("tent.2"),                 // Camping/Glamping
            .fa("caravan"),                // Campervan
            .fa("house-chimney"),          // Mountain hut
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
            .sf("paperclip"),
            .sf("questionmark.circle"),    // To try
            .sf("bookmark"),               // Bookmark
            .sf("camera.viewfinder"),      // Photo spot
            .sf("sparkles"),               // Hidden gem
            .sf("trophy"),                 // Best of
            .sf("lock"),                   // Private
            .sf("calendar"),               // Date/event
           ])
    ]
}
