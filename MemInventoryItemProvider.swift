//
//  MemInventoryItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 29/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class MemInventoryItemProvider {
    
    private var inventoryItems = [String: [InventoryItem]]()
    
    private let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func inventoryItems(inventory: Inventory) -> [InventoryItem]? {
        guard enabled else {return nil}
        
        return inventoryItems[inventory.uuid]
    }

    func inventoryItem(item: InventoryItem) -> InventoryItem? {
        guard enabled else {return nil}
        
        return inventoryItems[item.inventory.uuid]?.findFirst {$0.same(item)}
    }
    
    func addInventoryItems(inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItem in inventoryItems {
            addInventoryItem(inventoryItem)
        }
        return true
    }
    
    // Adds only the inventory items - this provider is not for history
    func addInventoryItems(inventoryItemsWithHistory: [InventoryItemWithHistoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItemWithHistory in inventoryItemsWithHistory {
            addInventoryItem(inventoryItemWithHistory.inventoryItem)
        }
        return true
    }
    
    func incrementInventoryItem(inventoryItem: InventoryItem, delta: Int) -> Bool {
        guard enabled else {return false}

        // increment only quantity - in mem cache we don't care about quantityDelta, this cache is only used by the UI, not to write objs to database or server
        let incremented = inventoryItem.copy(quantity: inventoryItem.quantity + delta)
        return updateInventoryItem(incremented)
    }
    
    /**
    * Appends inventory item to list or increments quantity if already exists
    */
    func addInventoryItem(inventoryItem: InventoryItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if inventoryItems[inventoryItem.inventory.uuid] == nil {
            inventoryItems[inventoryItem.inventory.uuid] = []
        }

        var found = false
        var items: [InventoryItem] = inventoryItems[inventoryItem.inventory.uuid]!
        for i in 0..<items.count {
            if items[i].same(inventoryItem) {
                items[i] = items[i].copy(quantity: items[i].quantity + inventoryItem.quantity) // increment quantity
                found = true
                break
            }
        }
        if !found {
            items.append(inventoryItem)
        }
        inventoryItems[inventoryItem.inventory.uuid] = items
        
        return true
    }
    
    func removeInventoryItem(inventoryItem: InventoryItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if inventoryItems[inventoryItem.inventory.uuid] != nil {
            inventoryItems[inventoryItem.inventory.uuid]?.remove(inventoryItem)
            return true
        } else {
            return false
        }
    }
    
    func removeInventoryItem(uuid: String, inventoryUuid: String) -> Bool {
        guard enabled else {return false}
        
        for (inventoryUuid, items) in inventoryItems {
            if inventoryUuid == inventoryUuid {
                for item in items {
                    if item.uuid == uuid {
                        inventoryItems[inventoryUuid]?.remove(item)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func updateInventoryItem(inventoryItem: InventoryItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if inventoryItems[inventoryItem.inventory.uuid] != nil {
            inventoryItems[inventoryItem.inventory.uuid]?.update(inventoryItem)
            return true
        } else {
            return false
        }
    }
    
    func updateInventoryItems(inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItem in inventoryItems {
            if !updateInventoryItem(inventoryItem) {
                return false
            }
        }
        return true
    }
    
    func overwrite(inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        invalidate()
        
        self.inventoryItems = inventoryItems.groupByInventory()
        
        return true
    }
    
    func invalidate() {
        guard enabled else {return}
        
        inventoryItems = [String: [InventoryItem]]()
    }
}

