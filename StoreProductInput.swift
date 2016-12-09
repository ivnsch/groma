//
//  StoreProductInput.swift
//  shoppin
//
//  Created by ischuetz on 08/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class StoreProductInput {
    
    let price: Float
    let baseQuantity: Float
    let unit: StoreProductUnit
    
    init(price: Float, baseQuantity: Float, unit: StoreProductUnit) {
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}

func ==(lhs: StoreProductInput, rhs: StoreProductInput) -> Bool {
    return lhs.price == rhs.price && lhs.baseQuantity == rhs.baseQuantity && lhs.unit == rhs.unit
}
