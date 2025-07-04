//
//  MemInventoryItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 29/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


class MemInventoryItemProvider {
    
    fileprivate var inventoryItems = [String: [InventoryItem]]()
    
    fileprivate let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func inventoryItems(_ inventory: DBInventory) -> [InventoryItem]? {
        guard enabled else {return nil}
        
        return inventoryItems[inventory.uuid]
    }

    func inventoryItem(_ item: InventoryItem) -> InventoryItem? {
        guard enabled else {return nil}
        
        return inventoryItems[item.inventory.uuid]?.findFirst {$0.same(item)}
    }
    
    func addInventoryItems(_ inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItem in inventoryItems {
            _ = addInventoryItem(inventoryItem)
        }
        return true
    }
    
    // Adds only the inventory items - this provider is not for history
    func addInventoryItems(_ inventoryItemsWithHistory: [InventoryItemWithHistoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItemWithHistory in inventoryItemsWithHistory {
            _ = addInventoryItem(inventoryItemWithHistory.inventoryItem)
        }
        return true
    }
    
    func incrementInventoryItem(_ inventoryItem: InventoryItem, delta: Float) -> Bool {
        guard enabled else {return false}

        // increment only quantity - in mem cache we don't care about quantityDelta, this cache is only used by the UI, not to write objs to database or server
        let incremented = inventoryItem.copy(quantity: inventoryItem.quantity + delta)
        return updateInventoryItem(incremented)
    }
    
    /**
    * Appends inventory item to list or increments quantity if already exists
    */
    func addInventoryItem(_ inventoryItem: InventoryItem) -> Bool {
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
    
    func removeInventoryItem(_ inventoryItem: InventoryItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if inventoryItems[inventoryItem.inventory.uuid] != nil {
            _ = inventoryItems[inventoryItem.inventory.uuid]?.remove(inventoryItem)
            return true
        } else {
            return false
        }
    }
    
    func removeInventoryItem(_ uuid: String, inventoryUuid: String) -> Bool {
        guard enabled else {return false}
        
        for (inventoryUuid, items) in inventoryItems {
            if inventoryUuid == inventoryUuid {
                for item in items {
                    if item.uuid == uuid {
                        _ = inventoryItems[inventoryUuid]?.remove(item)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func updateInventoryItem(_ inventoryItem: InventoryItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if inventoryItems[inventoryItem.inventory.uuid] != nil {
            _ = inventoryItems[inventoryItem.inventory.uuid]?.update(inventoryItem)
            return true
        } else {
            return false
        }
    }
    
    func updateInventoryItems(_ inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        for inventoryItem in inventoryItems {
            if !updateInventoryItem(inventoryItem) {
                return false
            }
        }
        return true
    }
    
    func overwrite(_ inventoryItems: [InventoryItem]) -> Bool {
        guard enabled else {return false}
        
        invalidate()
        
        self.inventoryItems = inventoryItems.groupByInventory()
        
        return true
    }
    
    func invalidate() {
        guard enabled else {return}
        
        inventoryItems = [String: [InventoryItem]]()
    }
    
    func inventoriesRealm(_ remote: Bool, _ handler: @escaping (ProviderResult<Results<DBInventory>>) -> Void) {
        logger.e("Not implemented (TODO)")
    }
}

