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
    public let quantity: Int
    public let section: String
    public let sectionColor: UIColor
    public let note: String?
    public let brand: String
    public let storeProductInput: StoreProductInput
    
    public init(name: String, quantity: Int, price: Float, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        self.name = name
        self.quantity = quantity
        self.section = section
        self.sectionColor = sectionColor
        self.note = note
        self.brand = brand
        self.storeProductInput = StoreProductInput(price: price, baseQuantity: baseQuantity, unit: unit)
    }
}


extension ListItemInput {
    
    func toProductPrototype() -> ProductPrototype {
        return ProductPrototype(name: name, category: section, categoryColor: sectionColor, brand: brand, baseQuantity: storeProductInput.baseQuantity, unit: storeProductInput.unit)
    }
}
