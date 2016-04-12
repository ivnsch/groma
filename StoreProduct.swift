//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

enum StoreProductUnit: Int {
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

final class StoreProduct: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
    let uuid: String
    let price: Float
    let product: Product
    let baseQuantity: Float
    let unit: StoreProductUnit
    let store: String
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: NSDate?
    let removed: Bool
    //////////////////////////////////////////////
    
    init(uuid: String, price: Float, baseQuantity: Float, unit: StoreProductUnit, store: String, product: Product, lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.price = price
        self.product = product
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.store = store
        
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), price: \(price), baseQuantity: \(baseQuantity), unit: \(unit), store: \(store), product: \(product), lastServerUpdate: \(lastServerUpdate), removed: \(removed)}"
    }
    
    var hashValue: Int {
        return self.uuid.hashValue
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil, category: ProductCategory? = nil, baseQuantity: Float? = nil, unit: StoreProductUnit? = nil, fav: Int? = nil, brand: String? = nil, store: String? = nil, product: Product? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> StoreProduct {
        return StoreProduct(
            uuid: uuid ?? self.uuid,
            price: price ?? self.price,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            store: store ?? self.store,
            product: product ?? self.product,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    func same(rhs: StoreProduct) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: StoreProduct, rhs: StoreProduct) -> Bool {
    return lhs.uuid == rhs.uuid
}

// convenience (redundant) holder to avoid having to iterate through products to find unique dependencies
typealias StoreProductsWithDependencies = (storeProducts: [StoreProduct], products: [Product], categories: [ProductCategory])