//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

enum ProductUnit: Int {
    case None = 0
    case Gram = 1
    case Kilogram = 2
    
    var text: String {
        switch self {
        case .None: return "None"
        case .Gram: return "Gram"
        case .Kilogram: return "Kilogram"
        }
    }
    
    var shortText: String {
        switch self {
        case .None: return ""
        case .Gram: return "g"
        case .Kilogram: return "kg"
        }
    }
}

final class Product: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let price: Float
    let category: ProductCategory
    let baseQuantity: Float
    let unit: ProductUnit
    var fav: Int
    
    init(uuid: String, name: String, price: Float, category: ProductCategory, baseQuantity: Float, unit: ProductUnit, fav: Int = 0) {
        self.uuid = uuid
        self.name = name
        self.price = price
        self.category = category
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.fav = fav
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), price: \(price), category: \(category), baseQuantity: \(baseQuantity), unit: \(unit), fav: \(fav)}"
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil, category: ProductCategory? = nil, baseQuantity: Float? = nil, unit: ProductUnit? = nil, fav: Int? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            price: price ?? self.price,
            category: category ?? self.category,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            fav: fav ?? self.fav
        )
    }
    
    func same(rhs: Product) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid
}