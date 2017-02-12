//
//  InventoryItemInput.swift
//  shoppin
//
//  Created by ischuetz on 11/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public struct InventoryItemInput {
    public let productPrototype: ProductPrototype
    public let quantity: Float
    
    public init(name: String, quantity: Float, category: String, categoryColor: UIColor, brand: String, unit: String) {
        self.productPrototype = ProductPrototype(name: name, category: category, categoryColor: categoryColor, brand: brand, unit: unit)
        self.quantity = quantity
    }
}
