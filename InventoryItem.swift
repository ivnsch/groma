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
    
    init(quantity: Int, product: Product) {
        self.quantity = quantity
        self.product = product
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) quantity: \(self.quantity), product: \(self.product)}"
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    // multiple inventories is not fully supported yet (also not in the server) so for now we assume there's only one inventory
    // in the future, though, we will support multiple inventories. The server's database is already configured for that.
    println("Warning: inventory item equals using only product, TODO add inventory reference (unique is inventory, product)")
    return lhs.product.uuid == rhs.product.uuid //&& lhs.inventory.uuid == rhs.inventory.uuid
}