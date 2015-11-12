//
//  PlanItemInput.swift
//  shoppin
//
//  Created by ischuetz on 08/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class PlanItemInput {
    
    let name: String
    let quantity: Int
    let price: Float
    let category: String
    let baseQuantity: Float
    let unit: ProductUnit
    
    init(name: String, quantity: Int, price: Float, category: String, baseQuantity: Float, unit: ProductUnit) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}