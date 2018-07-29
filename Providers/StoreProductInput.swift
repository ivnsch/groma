//
//  StoreProductInput.swift
//  shoppin
//
//  Created by ischuetz on 08/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public class StoreProductInput {
    public let refPrice: Float?
    public let refQuantity: Float?
    public let baseQuantity: Float
    public let secondBaseQuantity: Float
    public let unit: String
    
    public init(refPrice: Float?, refQuantity: Float?, baseQuantity: Float, secondBaseQuantity: Float, unit: String) {
        self.refPrice = refPrice
        self.refQuantity = refQuantity
        self.baseQuantity = baseQuantity
        self.secondBaseQuantity = secondBaseQuantity
        self.unit = unit
    }
}

public func ==(lhs: StoreProductInput, rhs: StoreProductInput) -> Bool {
    return lhs.refPrice == rhs.refPrice && lhs.refQuantity == rhs.refQuantity && lhs.baseQuantity == rhs.baseQuantity && lhs.secondBaseQuantity == rhs.secondBaseQuantity && lhs.unit == rhs.unit
}
