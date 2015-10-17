//
//  GroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct GroupItemInput {
    
    let name: String
    let quantity: Int
    let price: Float
    let section: String
    
    init(name: String, quantity: Int, price: Float, section: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.section = section
    }
}