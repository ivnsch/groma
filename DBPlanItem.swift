//
//  DBPlanItem.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class DBPlanItem: DBSyncable {
    
    dynamic var inventoryOpt: DBInventory? = DBInventory()
    dynamic var productOpt: Product? = Product()
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    
    dynamic var key: String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
            key = newProduct.uuid
        }
    }
    
    var inventory: DBInventory {
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
    
    override static func ignoredProperties() -> [String] {
        return ["product", "inventory"]
    }
}
