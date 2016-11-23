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
    
    func inventoryItems(_ inventory: Inventory, handler: @escaping (RemoteResult<[RemoteInventoryItemWithProduct]>) -> ()) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.inventoryItems, ["inventory": inventory.uuid as AnyObject]) {result in
            handler(result)
        }
    }

    // Adds inventoryItems to remote, IMPORTANT: All items are assumed to have the same inventory TODO maybe implement server service such that we don't have to put inventory uuid in url, and just use the inventory for each inventory item for the insert
    func addToInventory(_ inventoryItemsWithDelta: [(inventoryItem: InventoryItem, delta: Int)], handler: @escaping (RemoteResult<RemoteInventoryItemsWithDependencies>) -> ()) {
        
        func toParams(_ inventoryItemWithDelta: (inventoryItem: InventoryItem, delta: Int)) -> [String: AnyObject] {
            let productDict = RemoteListItemProvider().toRequestParams(inventoryItemWithDelta.inventoryItem.product)
            let inventoryDict = RemoteInventoryProvider().toRequestParams(inventoryItemWithDelta.inventoryItem.inventory)
            
            var dict: [String: AnyObject] = [
                "uuid": inventoryItemWithDelta.inventoryItem.uuid as AnyObject,
                "quantity": inventoryItemWithDelta.delta as AnyObject, // in this service the server does an "insert or increment" and interprets quantity as delta
                "inventory": inventoryDict as AnyObject,
                "product": productDict as AnyObject
            ]
            
            if let lastServerUpdate = inventoryItemWithDelta.inventoryItem.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
            }
            return dict
        }

        let parameters = inventoryItemsWithDelta.map{toParams($0)}
        RemoteProvider.authenticatedRequest(.post, Urls.inventoryItemsNoHistory, parameters) {result in
            handler(result)
        }
    }
    
    func updateInventoryItem(_ inventoryItem: InventoryItem, handler: @escaping (RemoteResult<RemoteInventoryItemWithProduct>) -> ()) {
        let params = toRequestParams(inventoryItem)
        RemoteProvider.authenticatedRequest(.put, Urls.inventoryItem, params) {result in
            handler(result)
        }
    }
    
    func removeInventoryItem(_ inventoryItem: InventoryItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        removeInventoryItem(inventoryItem.uuid, handler: handler)
    }

    func removeInventoryItem(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.inventoryItem + "/\(uuid)") {result in
            handler(result)
        }
    }

    func incrementInventoryItem(_ increment: ItemIncrement, handler: @escaping (RemoteResult<RemoteIncrementResult>) -> ()) {
        let params: [String: AnyObject] = [
            "uuid": increment.itemUuid as AnyObject,
            "delta": increment.delta as AnyObject
        ]
        RemoteProvider.authenticatedRequest(.post, Urls.incrementInventoryItem, params) {result in
            handler(result)
        }
    }
    
    // TODO remote inventory from inventory items, at least for sending - we want to add all the items to one inventory.......
    func toDictionary(_ item: InventoryItemWithHistoryItem) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(item.inventoryItem.product)
        
        let inventoryItemDict = toRequestParams(item.inventoryItem)
        
        // TODO correct this structure in the server, product 2x
        return [
            "product": productDict as AnyObject,
            "inventoryItem": inventoryItemDict as AnyObject,
            "historyItemUuid": item.historyItem.uuid as AnyObject,
            "paidPrice": item.historyItem.paidPrice as AnyObject,
            "addedDate": NSNumber(value: Int64(item.historyItem.addedDate) as Int64),
            "user": self.toRequestParams(item.historyItem.user) as AnyObject,
            "delta": item.historyItem.quantity as AnyObject // history item quantity == delta (the quantity which we just added)
        ]
    }
    
    fileprivate func toRequestParams(_ sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email as AnyObject,
            "foo": "" as AnyObject // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
    
    
    fileprivate func toRequestParams(_ inventoryItem: InventoryItem, quantityOverwrite: Int? = nil) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(inventoryItem.product)
        let inventoryDict = RemoteInventoryProvider().toRequestParams(inventoryItem.inventory)
        
        var dict: [String: AnyObject] = [
            "uuid": inventoryItem.uuid as AnyObject,
            "quantity": inventoryItem.quantity as AnyObject,
            "inventory": inventoryDict as AnyObject,
            "product": productDict as AnyObject
        ]
        
        if let lastServerUpdate = inventoryItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        }
        
        return dict
    }
}
