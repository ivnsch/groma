//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable {
    var quantity: Int // TODO?
    let product: Product
    let inventory: Inventory
    
    init(quantity: Int, product: Product, inventory: Inventory) {
        self.quantity = quantity
        self.product = product
        self.inventory = inventory
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) quantity: \(self.quantity), product: \(self.product), inventory: \(self.inventory)}"
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.product.uuid == rhs.product.uuid && lhs.inventory.uuid == rhs.inventory.uuid && lhs.quantity == rhs.quantity
}