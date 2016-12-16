//
//  ProductWithQuantityInput.swift
//  shoppin
//
//  Created by ischuetz on 10/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public struct ProductWithQuantityInput {
    public let product: StoreProduct
    public let quantity: Int
    
    public init(product: StoreProduct, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }
}
