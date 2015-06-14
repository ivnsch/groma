//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


final class Product: Equatable {
    let id: String
    let name: String
    let price: Float
    
    init(id: String, name: String, price: Float) {
        self.id = id
        self.name = name
        self.price = price
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.id == rhs.id
}