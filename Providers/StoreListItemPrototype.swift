//
//  ListItemPrototype.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// Represents an item that will be added to a list - it can come from e.g. quick add product or quick add group
public class StoreListItemPrototype: Equatable, Identifiable, CustomDebugStringConvertible {
    public let product: StoreProduct
    public let quantity: Int
    public let targetSectionName: String
    public let targetSectionColor: UIColor
    
    public init(product: StoreProduct, quantity: Int, targetSectionName: String, targetSectionColor: UIColor) {
        self.product = product
        self.quantity = quantity
        self.targetSectionName = targetSectionName
        self.targetSectionColor = targetSectionColor
    }
    
    public func same(_ rhs: StoreListItemPrototype) -> Bool {
        return product.same(rhs.product)
    }
    
    public var debugDescription: String {
        return "\(type(of: self)), product: \(product), quantity: \(quantity), targetSectionName: \(targetSectionName), targetSectionColor: \(targetSectionColor.hexStr)"
    }
    
}
public func ==(lhs: StoreListItemPrototype, rhs: StoreListItemPrototype) -> Bool {
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity && lhs.targetSectionColor == rhs.targetSectionColor
}
