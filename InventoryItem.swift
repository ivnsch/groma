//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable {
    let uuid: String
    var quantity: Int // TODO?
    let product: Product
    
    init(uuid: String, quantity: Int, product: Product) {
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), quantity: \(self.quantity), product: \(self.product)}"
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.uuid == rhs.uuid
}