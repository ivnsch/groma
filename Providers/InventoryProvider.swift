//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


public typealias InventoryItemWithHistoryItem = (inventoryItem: InventoryItem, historyItem: HistoryItem)

public protocol InventoryProvider {
    
    func inventories(_ remote: Bool, _ handler: @escaping (ProviderResult<RealmSwift.List<DBInventory>>) -> Void)
    
    
    // TODO remove
    func inventoriesRealm(_ remote: Bool, _ handler: @escaping (ProviderResult<Results<DBInventory>>) -> Void)
    
    /**
    Our app pricipially supports multiple inventories, but for now we will make it behave like there's only one
    So we work always with the first (only) inventory
    */
    func firstInventory(_ handler: @escaping (ProviderResult<DBInventory>) -> ())

    func addInventory(_ inventory: DBInventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func updateInventory(_ inventory: DBInventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], withoutNotifying: [NotificationToken], realm: Realm?, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func acceptInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func rejectInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void)
    
    
    // NEW
    
    func add(_ inventory: DBInventory, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func update(_ inventory: DBInventory, input: InventoryInput, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func move(from: Int, to: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(index: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
