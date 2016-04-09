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
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, brand: String) {
        self.productPrototype = ProductPrototype(name: name, price: price, category: category, categoryColor: categoryColor, brand: brand)
        self.quantity = quantity
    }
}
