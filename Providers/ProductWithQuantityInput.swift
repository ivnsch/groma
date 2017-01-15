//
//  ProductWithQuantityInput.swift
//  shoppin
//
//  Created by ischuetz on 10/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

// TODO rename StoreProductWithQuantityInput
public struct ProductWithQuantityInput {
    public let product: StoreProduct
    public let quantity: Int
    
    public init(product: StoreProduct, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }
}


// TODO put in own file
public struct QuantifiableProductWithQuantityInput {
    public let product: QuantifiableProduct
    public let quantity: Int
    
    public init(product: QuantifiableProduct, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }
}
