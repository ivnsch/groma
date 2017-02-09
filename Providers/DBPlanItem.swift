//
//  DBPlanItem.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class DBPlanItem: DBSyncable {
    
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var productOpt: Product? = Product() // this should be quantifiable product but we don't use plan items now so we let it like this for now
    public dynamic var quantity: Float = 0
    public dynamic var quantityDelta: Float = 0
    
    public dynamic var key: String = ""
    
    public override static func primaryKey() -> String? {
        return "key"
    }
    
    public var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
            key = newProduct.uuid
        }
    }
    
    public var inventory: DBInventory {
        get {
            return inventoryOpt ?? DBInventory()
        }
        set(newInventory) {
            inventoryOpt = newInventory
        }
    }
    
    // MARK: - Filters
    
    static func createFilterWithProduct(_ productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    // MARK: -
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "inventory"]
    }
}
