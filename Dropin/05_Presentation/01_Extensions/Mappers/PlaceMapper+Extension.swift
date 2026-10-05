//
//  PlaceMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation
import ContactFieldKit

@MainActor
extension PlaceMapper {
    
    static func toUI(_ place: Place, skipRelationships: Bool = false) -> PlaceUIModel {
        var groupUI: CategoryUIModel? = nil
        var tagsUI = [TagUIModel]()
        if !skipRelationships {
            tagsUI = place.tags.map { TagMapper.toUI($0) }
            if let category = place.category {
                groupUI = CategoryMapper.toUI(category)
            }
        }
        
        let phones = place.phone
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let emails = place.email
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let urls = place.url
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        
        let placeUI = PlaceUIModel(id: place.id,
                              name: place.name,
                              coordinates: place.coordinates,
                              address: place.address,
                              address2: place.address2,
                              tags: tagsUI,
                              category: groupUI,
                              images: place.images.map { PlaceImageUIModel(dbId: $0) },
                              icon: place.icon,
                              rating: place.rating,
                              phone: phones,
                              email: emails,
                              url: urls,
                              notes: place.notes,
                              applePlaceID: place.applePlaceID,
                              applePhone: place.applePhone,
                              appleURL: place.appleURL,
                              appleFetchedAt: place.appleFetchedAt,
                              createdAt: place.createdAt,
                              updatedAt: place.updatedAt,
                              deletedAt: place.deletedAt)
        if !skipRelationships {
            groupUI?.places.append(placeUI)
            for i in 0..<tagsUI.count {
                tagsUI[i].places.append(placeUI)
            }
        }
        return placeUI
    }
    
    static func toDomain(_ placeUI: PlaceUIModel, skipRelationships: Bool = false) -> Place {
        var category: Category? = nil
        var tags = [Tag]()
        if !skipRelationships {
            tags = placeUI.tags.map { TagMapper.toDomain($0) }
            if let groupUI = placeUI.category {
                category = CategoryMapper.toDomain(groupUI)
            }
        }
        let place = Place(id: placeUI.id,
                                name: placeUI.name,
                                coordinates: placeUI.coordinates,
                                address: placeUI.address,
                                address2: placeUI.address2,
                                tags: tags,
                                category: category,
                                images: placeUI.images.compactMap(\.dbId),
                                icon: placeUI.icon,
                                rating: placeUI.rating,
                                phone: placeUI.phone.map { $0.rawValue },
                                email: placeUI.email.map { $0.rawValue },
                                url: placeUI.url.map { $0.rawValue },
                                notes: placeUI.notes,
                                applePlaceID: placeUI.applePlaceID,
                                applePhone: placeUI.applePhone,
                                appleURL: placeUI.appleURL,
                                appleFetchedAt: placeUI.appleFetchedAt,
                                createdAt: placeUI.createdAt,
                                updatedAt: placeUI.updatedAt,
                                deletedAt: placeUI.deletedAt)
        return place
    }
}
