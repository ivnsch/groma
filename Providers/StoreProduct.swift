//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

public enum StoreProductUnit: Int {
    case none = 0
    case gram = 1
    case kilogram = 2
    
    public var text: String {
        switch self {
        case .none: return "None"
        case .gram: return "Gram"
        case .kilogram: return "Kilogram"
        }
    }
    
    public var shortText: String {
        switch self {
        case .none: return ""
        case .gram: return "g"
        case .kilogram: return "kg"
        }
    }
}

public final class StoreProduct: Equatable, Identifiable, CustomDebugStringConvertible {
    public let uuid: String
    public let price: Float
    public let product: Product
    public let baseQuantity: Float
    public let unit: StoreProductUnit
    public let store: String
    
    //////////////////////////////////////////////
    // sync properties - FIXME - while Realm allows to return Realm objects from async op. This shouldn't be in model objects.
    // the idea is that we can return the db objs from query and then do sync directly with these objs so no need to put sync attributes in model objs
    // we could map the db objects to other db objs in order to work around the Realm issue, but this adds even more overhead, we make a lot of mappings already
    let lastServerUpdate: Int64?
    let removed: Bool
    //////////////////////////////////////////////
    
    public init(uuid: String, price: Float, baseQuantity: Float, unit: StoreProductUnit, store: String, product: Product, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        self.uuid = uuid
        self.price = price
        self.product = product
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.store = store
        
        self.lastServerUpdate = lastServerUpdate
        self.removed = removed
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), price: \(price), baseQuantity: \(baseQuantity), unit: \(unit), store: \(store), product: \(product), lastServerUpdate: \(lastServerUpdate)::\(lastServerUpdate?.millisToEpochDate()), removed: \(removed)}"
    }
    
    public func copy(uuid: String? = nil, price: Float? = nil, baseQuantity: Float? = nil, unit: StoreProductUnit? = nil, store: String? = nil, product: Product? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> StoreProduct {
        return StoreProduct(
            uuid: uuid ?? self.uuid,
            price: price ?? self.price,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            store: store ?? self.store,
            product: product ?? self.product.copy(),
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // Overwrite all fields with fields of storeProduct, except uuid
    public func update(_ storeProduct: StoreProduct) -> StoreProduct {
        return copy(storeProduct, product: storeProduct.product)
    }
    
    public func update(_ storeProductInput: StoreProductInput) -> StoreProduct {
        return copy(price: storeProductInput.price, baseQuantity: storeProductInput.baseQuantity, unit: storeProductInput.unit)
    }
    
    // Updates self and its dependencies with storeProduct, the references to the dependencies (uuid) are not changed
    public func updateWithoutChangingReferences(_ storeProduct: StoreProduct) -> StoreProduct {
        let updatedProduct = product.updateWithoutChangingReferences(storeProduct.product)
        return update(storeProduct, product: updatedProduct)
    }

    fileprivate func update(_ storeProduct: StoreProduct, product: Product) -> StoreProduct {
        return copy(price: storeProduct.price, baseQuantity: storeProduct.baseQuantity, unit: storeProduct.unit, store: storeProduct.store, product: product, lastServerUpdate: storeProduct.lastServerUpdate, removed: storeProduct.removed)
    }
    
    fileprivate func copy(_ storeProduct: StoreProduct, product: Product) -> StoreProduct {
        return copy(price: storeProduct.price, baseQuantity: storeProduct.baseQuantity, unit: storeProduct.unit, store: storeProduct.store, product: product, lastServerUpdate: storeProduct.lastServerUpdate, removed: storeProduct.removed)
    }

    public func same(_ rhs: StoreProduct) -> Bool {
        return uuid == rhs.uuid
    }
    
    public func equalsExcludingSyncAttributes(_ rhs: StoreProduct) -> Bool {
        return uuid == rhs.uuid && price == rhs.price && product == rhs.product && baseQuantity == rhs.baseQuantity && unit == rhs.unit && store == rhs.store
    }
}

public func ==(lhs: StoreProduct, rhs: StoreProduct) -> Bool {
    return lhs.equalsExcludingSyncAttributes(rhs) && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// convenience (redundant) holder to avoid having to iterate through products to find unique dependencies
public typealias StoreProductsWithDependencies = (storeProducts: [StoreProduct], products: [Product], categories: [ProductCategory])
