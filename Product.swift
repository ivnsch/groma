//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class Product:Equatable {

    let name:String
    let price:Float
    let quantity:Int
    
    init(name:String, price:Float, quantity:Int) {
        self.name = name
        self.price = price
        self.quantity = quantity
    }
    
//    func description() -> String {
//        return ("\")
//    }

}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.name == rhs.name
}