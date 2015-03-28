//
//  ListItemInput.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

struct ListItemInput {

    let name:String
    let quantity:Int
    let price:Float
    let section:String
    
    init(name:String, quantity:Int, price:Float, section:String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.section = section
    }
}
