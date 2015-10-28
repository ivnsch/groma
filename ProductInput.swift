//
//  ProductInput.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class ProductInput: CustomDebugStringConvertible {

    let name: String
    let price: Float
    let category: String
    
    init(name: String, price: Float, category: String) {
        self.name = name
        self.price = price
        self.category = category
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(name), price: \(price), category: \(category)}"
    }
}