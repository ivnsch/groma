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
    let category: String
    
    init(uuid: String, name: String, price: Float, category: String) {
        self.uuid = uuid
        self.name = name
        self.price = price
        self.category = category
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), name: \(self.name), price: \(self.price), category: \(self.category)}"
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil, section: Section? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            price: price ?? self.price,
            category: category ?? self.category
        )
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid
}