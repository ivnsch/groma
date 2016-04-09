//
//  ProductWithQuantityInput.swift
//  shoppin
//
//  Created by ischuetz on 10/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

struct ProductWithQuantityInput {
    let product: StoreProduct
    let quantity: Int
    
    init(product: StoreProduct, quantity: Int) {
        self.product = product
        self.quantity = quantity
    }
}
