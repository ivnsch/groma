//
//  RemoteInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteInventoryProvider: RemoteProvider {
    
    func inventories(handler: RemoteResult<[RemoteInventory]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.inventory) {result in
            handler(result)
        }
    }
    
    func addInventory(inventory: Inventory, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        RemoteProvider.authenticatedRequest(.POST, Urls.inventory, params) {result in
            handler(result)
        }
    }
    
    func updateInventory(inventory: Inventory, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        RemoteProvider.authenticatedRequest(.PUT, Urls.inventory, params) {result in
            handler(result)
        }
    }

    
    func updateInventories(inventories: [Inventory], handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = inventories.map{self.toRequestParams($0)}
        // TODO this is no timplemented in the server
        RemoteProvider.authenticatedRequest(.PUT, Urls.inventories, params) {result in
            handler(result)
        }
    }
    
    func removeInventory(inventory: Inventory, handler: RemoteResult<NoOpSerializable> -> ()) {
        removeInventory(inventory.uuid, handler: handler)
    }

    func removeInventory(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.inventory + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func acceptInvitation(invitation: RemoteInventoryInvitation, handler: RemoteResult<NoOpSerializable> -> Void) {
        let parameters = toRequestParams(invitation, accept: true)
        RemoteProvider.authenticatedRequest(.POST, Urls.inventoryInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func rejectInvitation(invitation: RemoteInventoryInvitation, handler: RemoteResult<NoOpSerializable> -> Void) {
        let parameters = toRequestParams(invitation, accept: false)
        RemoteProvider.authenticatedRequest(.POST, Urls.inventoryInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func syncInventoriesWithInventoryItems(inventoriesSync: InventoriesSync, handler: RemoteResult<RemoteInventoriesWithInventoryItemsSyncResult> -> ()) {
        
        let inventoriesSyncDicts: [[String: AnyObject]] = inventoriesSync.inventoriesSyncs.map {inventorySync in
            
            let inventory = inventorySync.inventory
            
            let sharedUsers: [[String: AnyObject]] = inventory.users.map{self.toRequestParams($0)}
            
            var dict: [String: AnyObject] = [
                "uuid": inventory.uuid,
                "name": inventory.name,
                "users": sharedUsers,
            ]
            
            if let lastServerUpdate = inventory.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
            }
            
            let inventoryItemsDicts = inventorySync.inventoryItemsSync.inventoryItems.map {toRequestParamsForSync($0)}
            let toRemoveDicts = inventorySync.inventoryItemsSync.toRemove.map{self.toRequestParamsToRemove($0)}
            let inventoryItemsSyncDict: [String: AnyObject] = [
                "inventoryItems": inventoryItemsDicts,
                "toRemove": toRemoveDicts
            ]
            
            dict["inventoryItems"] = inventoryItemsSyncDict
            
            return dict
        }
        
        let toRemoveDicts = inventoriesSync.toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "inventories": inventoriesSyncDicts,
            "toRemove": toRemoveDicts
        ]
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.inventoriesWithItemsSync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteInventoriesWithInventoryItemsSyncResult>) in
            handler(result)
        }
    }
    

    // TODO maybe generally use this for inventoryItem request params?
    func toRequestParamsForSync(inventoryItem: InventoryItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "quantityDelta": inventoryItem.quantityDelta,
            "product": [
                "uuid": inventoryItem.product.uuid,
                "name": inventoryItem.product.name,
                "price": inventoryItem.product.price,
            ],
            "inventoryUuid": inventoryItem.inventory.uuid
        ]
        
        if let lastServerUpdate = inventoryItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        
        return dict
    }
    
    func toRequestParamsToRemove(inventoryItem: InventoryItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["inventoryUuid": inventoryItem.inventory.uuid, "productUuid": inventoryItem.product.uuid]
        if let lastServerUpdate = inventoryItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }
    
    func toRequestParamsToRemove(inventory: Inventory) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": inventory.uuid]
        if let lastServerUpdate = inventory.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }
    
    func toRequestParams(sharedUserInput: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUserInput.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }

    
    func toRequestParams(inventoryInput: Inventory) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = inventoryInput.users.map{self.toRequestParams($0)}
        
        var inventoryDict: [String: AnyObject] = [
            "uuid": inventoryInput.uuid,
            "name": inventoryInput.name,
            "order": inventoryInput.order,
            "color": inventoryInput.bgColor.hexStr
        ]

        if let lastServerUpdate = inventoryInput.lastServerUpdate {
            inventoryDict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        
        inventoryDict["users"] = sharedUsers
        
        return inventoryDict
    }
    
    func toRequestParams(invitation: RemoteInventoryInvitation, accept: Bool) -> [String: AnyObject] {
        return [
            "uuid": invitation.inventory.uuid,
            "accept": accept
        ]
    }
}
