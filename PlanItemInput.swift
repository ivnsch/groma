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
    
    init(name: String, quantity: Int, price: Float) {
        self.name = name
        self.quantity = quantity
        self.price = price
    }
}