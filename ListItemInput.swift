//
//  ListItemInput.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct ListItemInput {
    
    let name: String
    let quantity: Int
    let price: Float
    let section: String
    let note: String?
    
    init(name: String, quantity: Int, price: Float, section: String, note: String?) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.section = section
        self.note = note
    }
}