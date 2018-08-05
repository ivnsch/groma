//
//  ListItemInput.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO rename this is a generic input container from quick add that is used now not only in listitems but groups, inventory and products screen.
public struct ListItemInput {
    
    public let name: String
    public let quantity: Float
    public let section: String
    public let sectionColor: UIColor // TODO this should be hex - no UIKit in providers.
    public let note: String?
    public let brand: String
    public let edible: Bool
    public let storeProductInput: StoreProductInput
    
    public init(name: String, quantity: Float, refPrice: Float?, refQuantity: Float?, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, secondBaseQuantity: Float, unit: String, brand: String, edible: Bool) {
        self.name = name
        self.quantity = quantity
        self.section = section
        self.sectionColor = sectionColor
        self.note = note
        self.brand = brand
        self.edible = edible
        self.storeProductInput = StoreProductInput(refPrice: refPrice, refQuantity: refQuantity, baseQuantity: baseQuantity, secondBaseQuantity: secondBaseQuantity, unit: unit)
    }
}


extension ListItemInput {
    
    public func toProductPrototype() -> ProductPrototype {
        return ProductPrototype(name: name, category: section, categoryColor: sectionColor, brand: brand, baseQuantity: storeProductInput.baseQuantity, secondBaseQuantity: storeProductInput.secondBaseQuantity, unit: storeProductInput.unit, edible: edible)
    }
    
    var quantifiableProductUnique: QuantifiableProductUnique {
        return (name: name, brand: brand, unit: storeProductInput.unit, baseQuantity: storeProductInput.baseQuantity, secondBaseQuantity: storeProductInput.secondBaseQuantity)
    }
}
