//
//  RemoteInventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteInventoryItemsProvider: Any {
    
    func inventoryItems(inventory: Inventory, handler: RemoteResult<[RemoteInventoryItemWithProduct]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.inventoryItems, ["inventory": inventory.uuid]) {result in
            handler(result)
        }
    }

    // Adds inventoryItems to remote, IMPORTANT: All items are assumed to have the same inventory TODO maybe implement server service such that we don't have to put inventory uuid in url, and just use the inventory for each inventory item for the insert
    func addToInventory(inventoryItems: [InventoryItemWithHistoryEntry], handler: RemoteResult<RemoteInventoryItemsWithHistoryAndDependencies> -> ()) {
        let parameters = inventoryItems.map{[weak self] in self!.toDictionary($0)}
        if let inventoryUuid = inventoryItems.first?.inventoryItem.inventory.uuid {
            RemoteProvider.authenticatedRequest(.POST, Urls.inventoryItems + "/\(inventoryUuid)", parameters) {result in
                handler(result)
            }
        } else {
            print("Warn: RemoteInventoryItemsProvider.addToInventory: called without items. Remote service was not called.")
        }
    }
    
    func updateInventoryItem(inventoryItem: InventoryItem, handler: RemoteResult<RemoteInventoryItemWithProduct> -> ()) {
        let params = toRequestParams(inventoryItem)
        RemoteProvider.authenticatedRequest(.PUT, Urls.inventoryItem, params) {result in
            handler(result)
        }
    }
    
    func removeInventoryItem(inventoryItem: InventoryItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        removeInventoryItem(inventoryItem.uuid, handler: handler)
    }

    func removeInventoryItem(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.inventoryItem + "/\(uuid)") {result in
            handler(result)
        }
    }

    func incrementInventoryItem(increment: ItemIncrement, handler: RemoteResult<RemoteIncrementResult> -> ()) {
        let params: [String: AnyObject] = [
            "uuid": increment.itemUuid,
            "delta": increment.delta
        ]
        RemoteProvider.authenticatedRequest(.POST, Urls.incrementInventoryItem, params) {result in
            handler(result)
        }
    }
    
    // TODO remote inventory from inventory items, at least for sending - we want to add all the items to one inventory....... for receiving this also wastes payload, they also have the same inventory also
    private func toDictionary(inventoryItem: InventoryItemWithHistoryEntry) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(inventoryItem.inventoryItem.product)
        
        let inventoryItemDict = toRequestParams(inventoryItem.inventoryItem)
        
        // TODO correct this structure in the server, product 2x
        return [
            "product": productDict,
            "inventoryItem": inventoryItemDict,
            "historyItemUuid": inventoryItem.historyItemUuid,
            "paidPrice": inventoryItem.paidPrice,
            "addedDate": NSNumber(longLong: Int64(inventoryItem.addedDate)),
            "user": self.toRequestParams(inventoryItem.user)
        ]
    }
    
    private func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
    
    
    private func toRequestParams(inventoryItem: InventoryItem) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(inventoryItem.product)
        let inventoryDict = RemoteInventoryProvider().toRequestParams(inventoryItem.inventory)
        
        var dict: [String: AnyObject] = [
            "uuid": inventoryItem.uuid,
            "quantity": inventoryItem.quantityDelta,
            "inventory": inventoryDict,
            "product": productDict
        ]
        
        if let lastServerUpdate = inventoryItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
}
