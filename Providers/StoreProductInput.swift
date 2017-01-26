//
//  StoreProductInput.swift
//  shoppin
//
//  Created by ischuetz on 08/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public class StoreProductInput {
    
    public let price: Float // Pass -1 to signalize no update of price if store product already exists. TODO use optional
    public let baseQuantity: Float
    public let unit: ProductUnit
    
    public init(price: Float, baseQuantity: Float, unit: ProductUnit) {
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}

public func ==(lhs: StoreProductInput, rhs: StoreProductInput) -> Bool {
    return lhs.price == rhs.price && lhs.baseQuantity == rhs.baseQuantity && lhs.unit == rhs.unit
}
