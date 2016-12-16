//
//  InventorySync.swift
//  shoppin
//
//  Created by ischuetz on 09/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class InventorySync {
    public let inventory: DBInventory
    public let inventoryItemsSync: InventoryItemsSync
    
    public init(inventory: DBInventory, inventoryItemsSync: InventoryItemsSync) {
        self.inventory = inventory
        self.inventoryItemsSync = inventoryItemsSync
    }
}

public class InventoriesSync {
    
    public let inventoriesSyncs: [InventorySync]
    public let toRemove: [DBInventory]
    
    public init(inventoriesSyncs: [InventorySync], toRemove: [DBInventory]) {
        self.inventoriesSyncs = inventoriesSyncs
        self.toRemove = toRemove
    }
}

public class InventoryItemsSync {
    public let inventoryItems: [InventoryItem]
    public let toRemove: [InventoryItem]
    
    public init(inventoryItems: [InventoryItem], toRemove: [InventoryItem]) {
        self.inventoryItems = inventoryItems
        self.toRemove = toRemove
    }
}
