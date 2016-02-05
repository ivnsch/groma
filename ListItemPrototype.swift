//
//  ListItemPrototype.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Represents an item that will be added to a list - it can come from e.g. quick add product or quick add group
class ListItemPrototype: Equatable, Identifiable {
    let product: Product
    let quantity: Int
    let targetSectionName: String
    
    init(product: Product, quantity: Int, targetSectionName: String) {
        self.product = product
        self.quantity = quantity
        self.targetSectionName = targetSectionName
    }
    
    func same(rhs: ListItemPrototype) -> Bool {
        return product.same(rhs.product)
    }
    
    func incrementQuantityCopy(delta: Int) -> ProductWithQuantity {
        fatalError("override")
    }
}
func ==(lhs: ListItemPrototype, rhs: ListItemPrototype) -> Bool {
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity
}