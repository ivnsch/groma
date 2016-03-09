//
//  InventoryItemInput.swift
//  shoppin
//
//  Created by ischuetz on 11/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct InventoryItemInput {
    let name: String
    let quantity: Int
    let price: Float
    let category: String
    let categoryColor: UIColor    
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    let store: String
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
}
