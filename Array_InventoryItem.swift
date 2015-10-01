//
//  Array_InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 29/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: InventoryItem {
    
    /**
    Group list items by inventory (note that the inventory items inside each inventory are ordered but the inventories not)
    */
    func groupByInventory() -> [Inventory: [InventoryItem]] {
        var dictionary = [Inventory: [InventoryItem]]()
        for inventoryItem in self {
            if dictionary[inventoryItem.inventory] == nil {
                dictionary[inventoryItem.inventory] = []
            }
            dictionary[inventoryItem.inventory]?.append(inventoryItem)
        }
        return dictionary
    }
    
    func sortBy(sortBy: InventorySortBy) -> [Element] {
        switch sortBy {
        case .Alphabetic:
            return self.sort{$0.0.product.name < $0.1.product.name}
        case .Count:
            return self.sort{$0.0.quantity < $0.1.quantity}
        }
    }
}
