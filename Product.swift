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
    
    init(name:String, price:Float) {
        self.name = name
        self.price = price
    }
    
//    func description() -> String {
//        return ("\")
//    }

}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.name == rhs.name
}