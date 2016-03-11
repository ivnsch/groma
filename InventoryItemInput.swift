//
//  InventoryItemInput.swift
//  shoppin
//
//  Created by ischuetz on 11/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct InventoryItemInput {
    let productPrototype: ProductPrototype
    let quantity: Int
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.productPrototype = ProductPrototype(name: name, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit, brand: brand, store: store)
        self.quantity = quantity
    }
}
