//
//  InventorySync.swift
//  shoppin
//
//  Created by ischuetz on 09/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventorySync {
    let inventory: DBInventory
    let inventoryItemsSync: InventoryItemsSync
    
    init(inventory: DBInventory, inventoryItemsSync: InventoryItemsSync) {
        self.inventory = inventory
        self.inventoryItemsSync = inventoryItemsSync
    }
}

class InventoriesSync {
    
    let inventoriesSyncs: [InventorySync]
    let toRemove: [DBInventory]
    
    init(inventoriesSyncs: [InventorySync], toRemove: [DBInventory]) {
        self.inventoriesSyncs = inventoriesSyncs
        self.toRemove = toRemove
    }
}

class InventoryItemsSync {
    let inventoryItems: [InventoryItem]
    let toRemove: [InventoryItem]
    
    init(inventoryItems: [InventoryItem], toRemove: [InventoryItem]) {
        self.inventoryItems = inventoryItems
        self.toRemove = toRemove
    }
}
