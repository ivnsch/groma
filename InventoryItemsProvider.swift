//
//  InventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum InventorySortBy {
    case Alphabetic, Count
}

protocol InventoryItemsProvider {
    
    func inventoryItems(range: NSRange, inventory: Inventory, fetchMode: ProviderFetchModus, sortBy: InventorySortBy, _ handler: ProviderResult<[InventoryItem]> -> ())
    
    func addToInventory(inventory: Inventory, items: [InventoryItemWithHistoryEntry], _ handler: ProviderResult<Any> -> ())
    
    func addToInventory(inventory: Inventory, itemInput: InventoryItemInput, _ handler: ProviderResult<InventoryItemWithHistoryEntry> -> ())

    func updateInventoryItem(inventory: Inventory, item: InventoryItem, _ handler: ProviderResult<Any> -> Void)

    func incrementInventoryItem(item: InventoryItem, delta: Int, _ handler: ProviderResult<Any> -> ())
    
    func removeInventoryItem(item: InventoryItem, _ handler: ProviderResult<Any> -> ())
    
    func invalidateMemCache()
}
