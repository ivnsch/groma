//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

typealias InventoryItemWithHistoryItem = (inventoryItem: InventoryItem, historyItem: HistoryItem)

protocol InventoryProvider {
    
    func inventories(_ remote: Bool, _ handler: @escaping (ProviderResult<[Inventory]>) -> ())
    
    /**
    Our app pricipially supports multiple inventories, but for now we will make it behave like there's only one
    So we work always with the first (only) inventory
    */
    func firstInventory(_ handler: @escaping (ProviderResult<Inventory>) -> ())

    func addInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func updateInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func removeInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func removeInventory(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func acceptInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func rejectInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[SharedUser]>) -> Void)
}
