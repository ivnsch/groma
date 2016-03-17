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

    func countInventoryItems(inventory: Inventory, _ handler: ProviderResult<Int> -> Void)
    
    func addToInventory(inventory: Inventory, itemInput: ProductWithQuantityInput, remote: Bool, _ handler: ProviderResult<InventoryItemWithHistoryEntry> -> Void)
    
    func addToInventory(items: [InventoryItemWithHistoryEntry], remote: Bool, _ handler: ProviderResult<Any> -> ())

    func addToInventory(inventory: Inventory, itemInput: InventoryItemInput, _ handler: ProviderResult<InventoryItemWithHistoryEntry> -> Void)

    func addToInventory(inventory: Inventory, itemInputs: [ProductWithQuantityInput], remote: Bool, _ handler: ProviderResult<[InventoryItemWithHistoryEntry]> -> Void)
    
    func updateInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func incrementInventoryItem(item: InventoryItem, delta: Int, _ handler: ProviderResult<Any> -> ())
    
    func incrementInventoryItem(item: InventoryItemIncrement, remote: Bool, _ handler: ProviderResult<InventoryItem> -> ())

    func removeInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func removeInventoryItem(uuid: String, inventoryUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func invalidateMemCache()
}
