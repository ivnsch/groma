//
//  ItemInput.swift
//  Providers
//
//  Created by Ivan Schuetz on 08/02/2017.
//
//

import Foundation

public final class ItemInput: CustomDebugStringConvertible {
    
    public let name: String
//    public let category: ProductCategory // for now as full object, depending on requirements we may change this to category-input
    public let categoryName: String
    public let categoryColor: UIColor
    
    public init(name: String, categoryName: String, categoryColor: UIColor) {
        self.name = name
        self.categoryName = categoryName
        self.categoryColor = categoryColor
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), name: \(name), categoryName: \(categoryName), categoryColor: \(categoryColor)}"
    }
    
    var categoryInput: CategoryInput {
        return CategoryInput(name: categoryName, color: categoryColor)
    }
}


public final class CategoryInput: CustomDebugStringConvertible {
    
    public let name: String
    public let color: UIColor
    
    public init(name: String, color: UIColor) {
        self.name = name
        self.color = color
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), categoryName: \(name), categoryColor: \(color)}"
    }
}
