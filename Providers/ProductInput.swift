//
//  ProductInput.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public final class ProductInput: CustomDebugStringConvertible {

    public let name: String
    public let category: String
    public let categoryColor: UIColor
    public let brand: String
    
    public init(name: String, category: String, categoryColor: UIColor, brand: String) {
        self.name = name
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) name: \(name), category: \(category), categoryColor: \(categoryColor), brand: \(brand)}"
    }
}
