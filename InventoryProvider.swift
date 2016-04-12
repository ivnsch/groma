//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol InventoryProvider {
    
    func inventories(remote: Bool, _ handler: ProviderResult<[Inventory]> -> ())
    
    /**
    Our app pricipially supports multiple inventories, but for now we will make it behave like there's only one
    So we work always with the first (only) inventory
    */
    func firstInventory(handler: ProviderResult<Inventory> -> ())

    func addInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func updateInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func updateInventoriesOrder(orderUpdates: [OrderUpdate], remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func removeInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func removeInventory(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())
    
    func acceptInvitation(invitation: RemoteInventoryInvitation, _ handler: ProviderResult<Any> -> Void)
    
    func rejectInvitation(invitation: RemoteInventoryInvitation, _ handler: ProviderResult<Any> -> Void)
    
    func findInvitedUsers(listUuid: String, _ handler: ProviderResult<[SharedUser]> -> Void)
}
