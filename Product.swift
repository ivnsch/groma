//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

final class Product: Equatable, Hashable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let price: Float
    
    init(uuid: String, name: String, price: Float) {
        self.uuid = uuid
        self.name = name
        self.price = price
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), price: \(self.price)}"
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            price: price ?? self.price
        )
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid
}