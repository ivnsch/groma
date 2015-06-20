//
//  InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItem: Equatable {
    let product:Product
    var quantity:Int
    
    init(product:Product, quantity:Int) {
        self.product = product
        self.quantity = quantity
    }
}

func ==(lhs: InventoryItem, rhs: InventoryItem) -> Bool {
    return lhs.product == rhs.product
}