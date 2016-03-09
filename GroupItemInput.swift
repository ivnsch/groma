//
//  GroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct GroupItemInput: Equatable, Hashable {
    let name: String
    let quantity: Int
    let price: Float
    let category: String
    let categoryColor: UIColor
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    let store: String
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
    
    var hashValue: Int {
        return name.hashValue
    }
    
    func copy(name name: String? = nil, quantity: Int? = nil, price: Float? = nil, category: String? = nil, categoryColor: UIColor? = nil, baseQuantity: Float? = nil, unit: ProductUnit? = nil, brand: String? = nil, store: String? = nil) -> GroupItemInput {
        return GroupItemInput(
            name: name ?? self.name,
            quantity: quantity ?? self.quantity,
            price: price ?? self.price,
            category: category ?? self.category,
            categoryColor: categoryColor ?? self.categoryColor,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            brand: brand ?? self.brand,
            store: store ?? self.store
        )
    }
}

func ==(lhs: GroupItemInput, rhs: GroupItemInput) -> Bool {
    return lhs.name == rhs.name && lhs.quantity == rhs.quantity && lhs.price == rhs.price && lhs.category == rhs.category && lhs.categoryColor == rhs.categoryColor && lhs.baseQuantity == rhs.baseQuantity && lhs.unit == rhs.unit && lhs.brand == rhs.brand && lhs.store == rhs.store
}
