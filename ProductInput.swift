//
//  ProductInput.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class ProductInput: CustomDebugStringConvertible {

    let name: String
    let price: Float
    let category: String
    let baseQuantity: Float
    let unit: ProductUnit
    
    init(name: String, price: Float, category: String, baseQuantity: Float, unit: ProductUnit) {
        self.name = name
        self.price = price
        self.category = category
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(name), price: \(price), category: \(category), baseQuantity: \(baseQuantity), unit: \(unit)}"
    }
}