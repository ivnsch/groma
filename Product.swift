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
    let price: Float
    let category: ProductCategory
    let baseQuantity: Float
    let unit: ProductUnit
    var fav: Int
    let brand: String
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastUpdate: NSDate
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, name: String, price: Float, category: ProductCategory, baseQuantity: Float, unit: ProductUnit, fav: Int = 0, brand: String = "", lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.price = price
        self.category = category
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.fav = fav
        self.brand = brand
        
        self.lastUpdate = lastUpdate
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), price: \(price), category: \(category), baseQuantity: \(baseQuantity), unit: \(unit), fav: \(fav), brand: \(brand), lastUpdate: \(lastUpdate), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }

    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil, category: ProductCategory? = nil, baseQuantity: Float? = nil, unit: ProductUnit? = nil, fav: Int? = nil, brand: String? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            price: price ?? self.price,
            category: category ?? self.category,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            fav: fav ?? self.fav,
            brand: brand ?? self.brand,
            lastUpdate: lastUpdate ?? self.lastUpdate,
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