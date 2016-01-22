//
//  ProductCategory.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ProductCategory: Equatable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let color: UIColor
    
    init(uuid: String, name: String, color: UIColor) {
        self.uuid = uuid
        self.name = name
        self.color = color
    }
    
    private var shortDescription: String {
        return "{\(self.dynamicType) name: \(name)}"
    }
    
    private var longDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color)}"
    }
    
    var debugDescription: String {
        return shortDescription
    }
    
    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, color: UIColor? = nil) -> ProductCategory {
        return ProductCategory(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: color ?? self.color
        )
    }
    
    func same(rhs: ProductCategory) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: ProductCategory, rhs: ProductCategory) -> Bool {
    return lhs.uuid == rhs.uuid
}