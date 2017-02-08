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
    public let category: ProductCategory // for now as full object, depending on requirements we may change this to category-input
    
    public init(name: String, category: ProductCategory) {
        self.name = name
        self.category = category
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), name: \(name), category: \(category)}"
    }
}
