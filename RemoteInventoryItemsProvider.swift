//
//  RemoteInventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class RemoteInventoryItemsProvider: Any {
    
    func inventoryItems(inventory: Inventory, handler: RemoteResult<[RemoteInventoryItemWithProduct]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.inventoryItems, ["inventory": inventory.uuid]) {result in
            handler(result)
        }
    }

    // Adds inventoryItems to remote, IMPORTANT: All items are assumed to have the same inventory TODO maybe implement server service such that we don't have to put inventory uuid in url, and just use the inventory for each inventory item for the insert
    func addToInventory(inventoryItems: [InventoryItemWithHistoryItem], handler: RemoteResult<RemoteInventoryItemsWithHistoryAndDependencies> -> ()) {
        let parameters = inventoryItems.map{[weak self] in self!.toDictionary($0)}
        if let inventoryUuid = inventoryItems.first?.inventoryItem.inventory.uuid {
            RemoteProvider.authenticatedRequest(.POST, Urls.inventoryItems + "/\(inventoryUuid)", parameters) {result in
                handler(result)
            }
        } else {
            print("Warn: RemoteInventoryItemsProvider.addToInventory: called without items. Remote service was not called.")
        }
    }

    // Adds inventoryItems to remote, IMPORTANT: All items are assumed to have the same inventory TODO maybe implement server service such that we don't have to put inventory uuid in url, and just use the inventory for each inventory item for the insert
    func addToInventory(inventoryItemsWithDelta: [(inventoryItem: InventoryItem, delta: Int)], handler: RemoteResult<RemoteInventoryItemsWithDependencies> -> ()) {
        
        func toParams(inventoryItemWithDelta: (inventoryItem: InventoryItem, delta: Int)) -> [String: AnyObject] {
            let productDict = RemoteListItemProvider().toRequestParams(inventoryItemWithDelta.inventoryItem.product)
            let inventoryDict = RemoteInventoryProvider().toRequestParams(inventoryItemWithDelta.inventoryItem.inventory)
            
            var dict: [String: AnyObject] = [
                "uuid": inventoryItemWithDelta.inventoryItem.uuid,
                "quantity": inventoryItemWithDelta.delta, // in this service the server does an "insert or increment" and interprets quantity as delta
                "inventory": inventoryDict,
                "product": productDict
            ]
            
            if let lastServerUpdate = inventoryItemWithDelta.inventoryItem.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
            }
            return dict
        }

        let parameters = inventoryItemsWithDelta.map{toParams($0)}
        RemoteProvider.authenticatedRequest(.POST, Urls.inventoryItemsNoHistory, parameters) {result in
            handler(result)
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
    
    // TODO remote inventory from inventory items, at least for sending - we want to add all the items to one inventory.......
    func toDictionary(item: InventoryItemWithHistoryItem) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(item.inventoryItem.product)
        
        let inventoryItemDict = toRequestParams(item.inventoryItem)
        
        // TODO correct this structure in the server, product 2x
        return [
            "product": productDict,
            "inventoryItem": inventoryItemDict,
            "historyItemUuid": item.historyItem.uuid,
            "paidPrice": item.historyItem.paidPrice,
            "addedDate": NSNumber(longLong: Int64(item.historyItem.addedDate)),
            "user": self.toRequestParams(item.historyItem.user),
            "delta": item.historyItem.quantity // history item quantity == delta (the quantity which we just added)
        ]
    }
    
    private func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
    
    
    private func toRequestParams(inventoryItem: InventoryItem, quantityOverwrite: Int? = nil) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(inventoryItem.product)
        let inventoryDict = RemoteInventoryProvider().toRequestParams(inventoryItem.inventory)
        
        var dict: [String: AnyObject] = [
            "uuid": inventoryItem.uuid,
            "quantity": inventoryItem.quantity,
            "inventory": inventoryDict,
            "product": productDict
        ]
        
        if let lastServerUpdate = inventoryItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
}
