//
//  GroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public struct GroupItemInput: Equatable, Hashable {
    public let name: String
    public let quantity: Int
    public let category: String
    public let categoryColor: UIColor
    public let brand: String
    
    public init(name: String, quantity: Int, category: String, categoryColor: UIColor, brand: String) {
        self.name = name
        self.quantity = quantity
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
    }
    
    public var hashValue: Int {
        return name.hashValue
    }
    
    public func copy(name: String? = nil, quantity: Int? = nil, category: String? = nil, categoryColor: UIColor? = nil, brand: String? = nil) -> GroupItemInput {
        return GroupItemInput(
            name: name ?? self.name,
            quantity: quantity ?? self.quantity,
            category: category ?? self.category,
            categoryColor: categoryColor ?? self.categoryColor,
            brand: brand ?? self.brand
        )
    }
}

public func ==(lhs: GroupItemInput, rhs: GroupItemInput) -> Bool {
    return lhs.name == rhs.name && lhs.quantity == rhs.quantity && lhs.category == rhs.category && lhs.categoryColor == rhs.categoryColor && lhs.brand == rhs.brand
}
