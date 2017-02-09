//
//  IngredientInput.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/01/2017.
//
//

import Foundation

public struct IngredientInput: Equatable, Hashable {
    public let name: String
    public let quantity: Float
    public let category: String
    public let categoryColor: UIColor
    public let brand: String
    public let unit: ProductUnit
    public let baseQuantity: String // TODO!!!!!!!!! remove
    
    public init(name: String, quantity: Float, category: String, categoryColor: UIColor, brand: String, unit: ProductUnit, baseQuantity: String) {
        self.name = name
        self.quantity = quantity
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
        self.unit = unit
        self.baseQuantity = baseQuantity
    }
    
    public var hashValue: Int {
        return name.hashValue
    }
    
    public func copy(name: String? = nil, quantity: Float? = nil, category: String? = nil, categoryColor: UIColor? = nil, brand: String? = nil, unit: ProductUnit? = nil, baseQuantity: String? = nil) -> IngredientInput {
        return IngredientInput(
            name: name ?? self.name,
            quantity: quantity ?? self.quantity,
            category: category ?? self.category,
            categoryColor: categoryColor ?? self.categoryColor,
            brand: brand ?? self.brand,
            unit: unit ?? self.unit,
            baseQuantity: baseQuantity ?? self.baseQuantity
        )
    }
}

public func ==(lhs: IngredientInput, rhs: IngredientInput) -> Bool {
    return lhs.name == rhs.name && lhs.quantity == rhs.quantity && lhs.category == rhs.category && lhs.categoryColor == rhs.categoryColor && lhs.brand == rhs.brand && lhs.unit == rhs.unit && lhs.baseQuantity == rhs.baseQuantity
}


// TODO better name, this is also used by input form after the item was retrieved from db
public struct QuickAddIngredientInput: Equatable, Hashable {
    public let item: Item
    public let quantity: Float
    public let unit: ProductUnit
    
    public init(item: Item, quantity: Float, unit: ProductUnit) {
        self.item = item
        self.quantity = quantity
        self.unit = unit
    }
    
    public var hashValue: Int {
        return item.uuid.hashValue
    }
    
    public func copy(item: Item? = nil, quantity: Float? = nil, unit: ProductUnit? = nil) -> QuickAddIngredientInput {
        return QuickAddIngredientInput(
            item: item ?? self.item,
            quantity: quantity ?? self.quantity,
            unit: unit ?? self.unit
        )
    }
}

public func ==(lhs: QuickAddIngredientInput, rhs: QuickAddIngredientInput) -> Bool {
    return lhs.item == rhs.item && lhs.quantity == rhs.quantity && lhs.unit == rhs.unit
}
