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
    let category: ProductCategory
    var fav: Int
    let brand: String

    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, category: ProductCategory, fav: Int = 0, brand: String = "", lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.category = category
        self.fav = fav
        self.brand = brand
        
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), category: \(category), fav: \(fav), brand: \(brand), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, category: ProductCategory? = nil, fav: Int? = nil, brand: String? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            category: category ?? self.category,
            fav: fav ?? self.fav,
            brand: brand ?? self.brand,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(rhs: Product) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid
}

// convenience (redundant) holder to avoid having to iterate through listitems to find unique categories
typealias ProductsWithDependencies = (products: [Product], categories: [ProductCategory])
