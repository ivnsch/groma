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
    
    init(name: String, quantity: Int, price: Float, category: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
    }
}