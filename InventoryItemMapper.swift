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
        return InventoryItem(uuid: dbInventoryItem.uuid, quantity: dbInventoryItem.quantity, product: product)
    }
    
    class func inventoryItemWithRemote(remoteItem: RemoteInventoryItemWithProduct) -> InventoryItem {
        let product = ProductMapper.ProductWithRemote(remoteItem.product)
        return InventoryItem(uuid: remoteItem.inventoryItem.uuid, quantity: remoteItem.inventoryItem.quantity, product: product)
    }
    
    class func dbWithInventoryItem(item: InventoryItem) -> DBInventoryItem {
        let db = DBInventoryItem()
        db.uuid = item.uuid
        db.quantity = item.quantity
        db.product = ProductMapper.dbWithProduct(item.product)
        return db
    }
}