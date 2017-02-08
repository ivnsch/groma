//
//  Array_InventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 29/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array where Element: InventoryItem {
    
    /**
    Group list items by inventory (note that the inventory items inside each inventory are ordered but the inventories not)
    */
    public func groupByInventory() -> [String: [InventoryItem]] {
        var dictionary = [String: [InventoryItem]]()
        for inventoryItem in self {
            if dictionary[inventoryItem.inventory.uuid] == nil {
                dictionary[inventoryItem.inventory.uuid] = []
            }
            dictionary[inventoryItem.inventory.uuid]?.append(inventoryItem)
        }
        return dictionary
    }
    
    public func sortBy(_ sortBy: InventorySortBy) -> [Element] {
        switch sortBy {
        case .alphabetic:
            return sorted{
                if $0.0.product.product.item.name == $0.1.product.product.item.name {
                    if $0.0.quantity == $0.1.quantity {
                        return $0.0.product.unit.text < $0.1.product.unit.text
                    } else {
                        return $0.0.quantity < $0.1.quantity
                    }
                    
                } else {
                    return $0.0.product.product.item.name < $0.1.product.product.item.name
                }
            }
        case .count:
            return sorted{
                if $0.0.quantity == $0.1.quantity {
                    if $0.0.product.product.item.name == $0.1.product.product.item.name {
                        return $0.0.product.unit.text < $0.1.product.unit.text
                    } else {
                        return $0.0.product.product.item.name < $0.1.product.product.item.name
                    }
                } else {
                    return $0.0.quantity < $0.1.quantity
                }
            }
        }
    }
}
