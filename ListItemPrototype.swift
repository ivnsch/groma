//
//  ListItemPrototype.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Represents an item that will be added to a list - it can come from e.g. quick add product, quick add group or add new list item. In the latest case, storeProductInput is set.
class ListItemPrototype: Equatable, Identifiable, CustomDebugStringConvertible {
    let product: Product
    let quantity: Int
    let targetSectionName: String
    let targetSectionColor: UIColor
    let storeProductInput: StoreProductInput?
    
    init(product: Product, quantity: Int, targetSectionName: String, targetSectionColor: UIColor, storeProductInput: StoreProductInput?) {
        self.product = product
        self.quantity = quantity
        self.targetSectionName = targetSectionName
        self.targetSectionColor = targetSectionColor
        self.storeProductInput = storeProductInput
    }
    
    func same(_ rhs: ListItemPrototype) -> Bool {
        return product.same(rhs.product)
    }
    
    var debugDescription: String {
        return "\(product.name), \(quantity), \(targetSectionName)"
    }
    
    func copy(product: Product? = nil, quantity: Int? = nil, targetSectionName: String? = nil, targetSectionColor: UIColor? = nil, storeProductInput: StoreProductInput? = nil) -> ListItemPrototype {
        return ListItemPrototype(
            product: product ?? self.product.copy(),
            quantity: quantity ?? self.quantity,
            targetSectionName: targetSectionName ?? self.targetSectionName,
            targetSectionColor: targetSectionColor ?? self.targetSectionColor,
            storeProductInput: storeProductInput ?? self.storeProductInput
        )
    }
}
func ==(lhs: ListItemPrototype, rhs: ListItemPrototype) -> Bool {
    
    let storeProductInputsEqual: Bool = {
        if let lhsStoreProductInput = lhs.storeProductInput, let rhsStoreProductInput = rhs.storeProductInput {
            return lhsStoreProductInput == rhsStoreProductInput
        } else if lhs.storeProductInput == nil && rhs.storeProductInput == nil {
            return true
        } else { // only one of them is nil
            return false
        }
    }()
    
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity && lhs.targetSectionColor == rhs.targetSectionColor && storeProductInputsEqual
}
