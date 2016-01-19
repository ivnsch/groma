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
    let categoryColor: UIColor
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
    }
}