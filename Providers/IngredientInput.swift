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
    public let brand: String // TODO!!!!!!!!! remove
    public let unit: Unit
    public let baseQuantity: Float // TODO!!!!!!!!! remove
    // TODO add fraction

    public init(name: String, quantity: Float, category: String, categoryColor: UIColor, brand: String, unit: Unit, baseQuantity: Float) {
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
    
    public func copy(name: String? = nil, quantity: Float? = nil, category: String? = nil, categoryColor: UIColor? = nil, brand: String? = nil, unit: Unit? = nil, baseQuantity: Float? = nil) -> IngredientInput {
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
    public let unit: Unit
    public let fraction: Fraction
    
    public init(item: Item, quantity: Float, unit: Unit, fraction: Fraction) {
        self.item = item
        self.quantity = quantity
        self.unit = unit
        self.fraction = fraction
    }
    
    public var hashValue: Int {
        return item.uuid.hashValue
    }
    
    public func copy(item: Item? = nil, quantity: Float? = nil, unit: Unit? = nil, fraction: Fraction? = nil) -> QuickAddIngredientInput {
        return QuickAddIngredientInput(
            item: item ?? self.item,
            quantity: quantity ?? self.quantity,
            unit: unit ?? self.unit,
            fraction: fraction ?? self.fraction
        )
    }
}

public func ==(lhs: QuickAddIngredientInput, rhs: QuickAddIngredientInput) -> Bool {
    return lhs.item == rhs.item && lhs.quantity == rhs.quantity && lhs.unit == rhs.unit && lhs.fraction == rhs.fraction
}


public struct Fraction: Equatable {
    
    public var wholeNumber: Int // TODO remove - not used anymore. Whole number is the quantity
    public var numerator: Int
    public var denominator: Int
    
    public init(numerator: Int, denominator: Int) {
        self.init(wholeNumber: 0, numerator: numerator, denominator: denominator)
    }
    
    public init(wholeNumber: Int, numerator: Int, denominator: Int) {
        self.wholeNumber = wholeNumber
        self.numerator = numerator
        self.denominator = denominator
    }
    
    public var decimalValue: Float {
        guard denominator != 0 else {logger.e("Invalid state: denominator is 0. Returning 0"); return 0}
        return Float(wholeNumber) + (Float(numerator) / Float(denominator))
    }
    
    public var isZero: Bool {
        return decimalValue == 0
    }
    
    public var isOne: Bool {
        return decimalValue == 1
    }
    
    public var isOneByOne: Bool {
        return numerator == 1 && denominator == 1
    }
    
    public var isValid: Bool {
        return denominator != 0
    }
    
    public var isValidAndNotZeroOrOne: Bool {
        return isValid && !isZero && !isOne
    }

    public var isValidAndNotZeroOrOneByOne: Bool {
        return isValid && !isZero && !isOneByOne
    }
    
    public var description: String {
        let wholeNumberStr = wholeNumber == 0 ? "" : "\(wholeNumber)"
        return "\(wholeNumberStr)\(numerator)/\(denominator)"
    }
    
    public static var zero: Fraction {
        return Fraction(wholeNumber: 0, numerator: 0, denominator: 1)
    }
    
    // We could also use 1, 0, 1, but since will likely remove wholeNumber we do like if it wasn't there already. 
    public static var one: Fraction {
        return Fraction(wholeNumber: 0, numerator: 1, denominator: 1)
    }
}

// We define equality as having identical components not the result/internal value (decimalValue)
public func ==(lhs: Fraction, rhs: Fraction) -> Bool {
    return lhs.wholeNumber == rhs.wholeNumber && lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}
