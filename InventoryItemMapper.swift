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
        let product = ProductMapper.ProductWithRemote(remoteItem.product)
        return InventoryItem(quantity: remoteItem.inventoryItem.quantity, product: product, inventory: inventory)
    }
    
    class func dbWithInventoryItem(item: InventoryItem) -> DBInventoryItem {
        let db = DBInventoryItem()
        db.quantity = item.quantity
        db.quantityDelta = item.quantityDelta
        db.product = ProductMapper.dbWithProduct(item.product)
        db.inventory = InventoryMapper.dbWithInventory(item.inventory)
        return db
    }
}