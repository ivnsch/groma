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
    public let refPrice: Float?
    public let refQuantity: Float?
    public let baseQuantity: Float
    public let unit: String
    
    public init(price: Float, refPrice: Float?, refQuantity: Float?, baseQuantity: Float, unit: String) {
        self.price = price
        self.refPrice = refPrice
        self.refQuantity = refQuantity
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}

public func ==(lhs: StoreProductInput, rhs: StoreProductInput) -> Bool {
    return lhs.price == rhs.price && lhs.refPrice == rhs.price && lhs.refQuantity == rhs.refQuantity && lhs.baseQuantity == rhs.baseQuantity && lhs.unit == rhs.unit
}
