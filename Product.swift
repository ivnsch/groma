//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


final class Product: Equatable {
    let uuid: String
    let name: String
    let price: Float
    
    init(uuid: String, name: String, price: Float) {
        self.uuid = uuid
        self.name = name
        self.price = price
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid
}