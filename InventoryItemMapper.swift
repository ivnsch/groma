//
//  InventoryItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItemMapper {
    
    class func inventoryItemWithDB(dbInventoryItem: DBInventoryItem) -> InventoryItem {
        let product = ProductMapper.productWithDB(dbInventoryItem.product)
        let inventory = InventoryMapper.inventoryWithDB(dbInventoryItem.inventory)
        return InventoryItem(quantity: dbInventoryItem.quantity, quantityDelta: dbInventoryItem.quantityDelta, product: product, inventory: inventory)
    }
    
    class func inventoryItemWithRemote(remoteItem: RemoteInventoryItemWithProduct, inventory: Inventory) -> InventoryItem {
        let product = ProductMapper.productWithRemote(remoteItem.product, category: remoteItem.productCategory)
        return InventoryItem(quantity: remoteItem.inventoryItem.quantity, product: product, inventory: inventory)
    }
    
    class func dbWithInventoryItem(item: InventoryItem) -> DBInventoryItem {
        let db = DBInventoryItem()
        db.quantity = item.quantity
        db.quantityDelta = item.quantityDelta
        db.product = ProductMapper.dbWithProduct(item.product)
        db.inventory = InventoryMapper.dbWithInventory(item.inventory)
        db.lastUpdate = item.lastUpdate
        if let lastServerUpdate = item.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            db.lastServerUpdate = lastServerUpdate
        }
        return db
    }
    
    class func dbInventoryItemWithRemote(item: RemoteInventoryItemWithProduct, inventory: DBInventory) -> DBInventoryItem {
        let product = ProductMapper.dbProductWithRemote(item.product, category: item.productCategory)
        
        let db = DBInventoryItem()
        db.quantity = item.inventoryItem.quantity
        db.product = product
        db.inventory = inventory
        db.lastServerUpdate = item.inventoryItem.lastUpdate
        db.dirty = false
        return db
    }
}