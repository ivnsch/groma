//
//  InventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO generic name and put somewhere else, this is also being used by group items (e.g. ProductWithQuantitySortBy)
public enum InventorySortBy {
    case alphabetic, count
}

public protocol InventoryItemsProvider {
    
    func inventoryItems(inventory: DBInventory, fetchMode: ProviderFetchModus, sortBy: InventorySortBy, _ handler: @escaping (ProviderResult<Results<InventoryItem>>) -> Void)

    func countInventoryItems(_ inventory: DBInventory, _ handler: @escaping (ProviderResult<Int>) -> Void)

    // Add inventory and history items in a transaction. Used by e.g. websocket
    func addToInventoryLocal(_ inventoryItems: [InventoryItem], historyItems: [HistoryItem], dirty: Bool, handler: @escaping (ProviderResult<Any>) -> Void)

    // Update with removal of possible already existing item with same unique in same inventory and unique reference update
    func updateInventoryItem(_ input: InventoryItemInput, updatingInventoryItem: InventoryItem, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<UpdateInventoryItemResult>) -> Void)

    // Plain update without additional checks
    func updateInventoryItem(_ item: InventoryItem, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)

    // For websocket - simply upserts the inventory item, does not any checks or re-referencing of dependencies.
    func addOrUpdateLocal(_ inventoryItems: [InventoryItem], _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func incrementInventoryItem(_ item: InventoryItem, delta: Float, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<Float>) -> Void)
    
    func incrementInventoryItem(_ item: ItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<InventoryItem>) -> ())

    func removeInventoryItem(_ item: InventoryItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func removeInventoryItem(_ uuid: String, inventoryUuid: String, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func invalidateMemCache()
    
    // MARK: - Direct (no history)
    
    // Add product
    func addToInventory(_ inventory: DBInventory, product: QuantifiableProduct, quantity: Float, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<(inventoryItem: InventoryItem, delta: Float, isNew: Bool)>) -> Void)
    
    // Add group
    func addToInventory(_ inventory: DBInventory, group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<[(inventoryItem: InventoryItem, delta: Float)]>) -> Void)
    
    // Add inventory item input
    func addToInventory(_ inventory: DBInventory, itemInput: InventoryItemInput, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<(inventoryItem: InventoryItem, delta: Float, isNew: Bool)>) -> Void)
}
