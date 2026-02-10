//
//  LabeledValueRowUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/2/26.
//

import Foundation
   
struct LabeledValueRowUI: Equatable {
    static let rowHeight: CGFloat = 45

    var height: CGFloat
    var opacity: CGFloat
    var clip: Bool
    var separatorOpacity: CGFloat
    var offset: CGFloat
    var removeButtonOpacity: CGFloat
    var deleteFrame: CGRect

    var toBeDeleted: Bool = false
    //var deleting: Bool = false

    var entityLabeledValue: EntityLabeledValue
    
    init(entityLabeledValue: EntityLabeledValue) {
        self.entityLabeledValue = entityLabeledValue
        // Default
        self.height = LabeledValueRowUI.rowHeight
        self.opacity = 1
        self.clip = false
        self.separatorOpacity = 1
        self.offset = 0
        self.removeButtonOpacity = 1
        self.deleteFrame = .zero
    }
    
    init(kind: EntityLabeledValue.TypeWithLabel.Kind,
         height: CGFloat,
         opacity: CGFloat,
         clip: Bool,
         separatorOpacity: CGFloat,
         removeButtonOpacity: CGFloat) {
        self.entityLabeledValue = EntityLabeledValue(kind: kind)
        
        self.height = height
        self.opacity = opacity
        self.clip = clip
        self.separatorOpacity = separatorOpacity
        self.offset = 0
        self.removeButtonOpacity = removeButtonOpacity
        self.deleteFrame = .zero
    }
}
