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
    let brand: String
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, brand: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
    }
    
    var hashValue: Int {
        return name.hashValue
    }
    
    func copy(name name: String? = nil, quantity: Int? = nil, price: Float? = nil, category: String? = nil, categoryColor: UIColor? = nil, brand: String? = nil) -> GroupItemInput {
        return GroupItemInput(
            name: name ?? self.name,
            quantity: quantity ?? self.quantity,
            price: price ?? self.price,
            category: category ?? self.category,
            categoryColor: categoryColor ?? self.categoryColor,
            brand: brand ?? self.brand
        )
    }
}

func ==(lhs: GroupItemInput, rhs: GroupItemInput) -> Bool {
    return lhs.name == rhs.name && lhs.quantity == rhs.quantity && lhs.price == rhs.price && lhs.category == rhs.category && lhs.categoryColor == rhs.categoryColor && lhs.brand == rhs.brand
}
