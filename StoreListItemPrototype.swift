//
//  ListItemPrototype.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Represents an item that will be added to a list - it can come from e.g. quick add product or quick add group
class StoreListItemPrototype: Equatable, Identifiable, CustomDebugStringConvertible {
    let product: StoreProduct
    let quantity: Int
    let targetSectionName: String
    let targetSectionColor: UIColor
    
    init(product: StoreProduct, quantity: Int, targetSectionName: String, targetSectionColor: UIColor) {
        self.product = product
        self.quantity = quantity
        self.targetSectionName = targetSectionName
        self.targetSectionColor = targetSectionColor
    }
    
    func same(_ rhs: StoreListItemPrototype) -> Bool {
        return product.same(rhs.product)
    }
    
    var debugDescription: String {
        return "\(type(of: self)), product: \(product), quantity: \(quantity), targetSectionName: \(targetSectionName), targetSectionColor: \(targetSectionColor.hexStr)"
    }
    
}
func ==(lhs: StoreListItemPrototype, rhs: StoreListItemPrototype) -> Bool {
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity && lhs.targetSectionColor == rhs.targetSectionColor
}
