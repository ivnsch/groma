//
//  ProductWithQuantity.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class ProductWithQuantity: Equatable, Identifiable {
    var product: Product {
        fatalError("override")
    }
    var quantity: Int {
        fatalError("override")
    }
    func same(rhs: ProductWithQuantity) -> Bool {
        return product.same(rhs.product)
    }
    func incrementQuantityCopy(delta: Int) -> ProductWithQuantity {
        fatalError("override")
    }
}
func ==(lhs: ProductWithQuantity, rhs: ProductWithQuantity) -> Bool {
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity
}