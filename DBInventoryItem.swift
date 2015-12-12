//
//  DBInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventoryItem: DBSyncable {
    
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    dynamic var product: DBProduct = DBProduct()
    dynamic var inventory: DBInventory = DBInventory()
    
    dynamic lazy var compoundKey: String = self.compoundKeyValue()

    private func compoundKeyValue() -> String {
        return "\(product.uuid)-\(inventory.uuid)"
    }

    override static func primaryKey() -> String {
        return "compoundKey"
    }
    
    // MARK: - Query utilities

    static func createFilter(item: InventoryItem) -> String {
        return createFilter(item.product.uuid, item.inventory.uuid)
    }
    
    static func createFilter(product: Product, _ inventory: Inventory) -> String {
        return createFilter(product.uuid, inventory.uuid)
    }
    
    static func createFilter(productUuid: String, _ inventoryUuid: String) -> String {
        return "product.uuid = '\(productUuid)' AND inventory.uuid = '\(inventoryUuid)'"
    }
}