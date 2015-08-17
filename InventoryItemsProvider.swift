//
//  InventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol InventoryItemsProvider {
    
    func inventoryItems(inventory: Inventory, _ handler: ProviderResult<[InventoryItem]> -> ())
    
    func addToInventory(inventory: Inventory, items: [InventoryItemWithHistoryEntry], _ handler: ProviderResult<Any> -> ())
    
    func updateInventoryItem(inventory: Inventory, item: InventoryItem)

}
