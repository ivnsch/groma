//
//  RemoteInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteInventoryProvider: RemoteProvider {
    
    func inventories(_ handler: @escaping (RemoteResult<[RemoteInventoryWithDependencies]>) -> ()) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.inventory) {result in
            handler(result)
        }
    }
    
    func addInventory(_ inventory: DBInventory, handler: @escaping (RemoteResult<RemoteInventoryWithDependencies>) -> ()) {
        let params = self.toRequestParams(inventory)
        RemoteProvider.authenticatedRequest(.post, Urls.inventory, params) {result in
            handler(result)
        }
    }
    
    func updateInventory(_ inventory: DBInventory, handler: @escaping (RemoteResult<RemoteInventoryWithDependencies>) -> ()) {
        let params = self.toRequestParams(inventory)
        RemoteProvider.authenticatedRequest(.put, Urls.inventory, params) {result in
            handler(result)
        }
    }

//    // TODO!!!! server - also handle return to update timestamps
//    func updateInventories(inventories: [Inventory], handler: RemoteResult<NoOpSerializable> -> ()) {
//        let params = inventories.map{self.toRequestParams($0)}
//        // TODO this is no timplemented in the server
//        RemoteProvider.authenticatedRequest(.PUT, Urls.inventories, params) {result in
//            handler(result)
//        }
//    }

    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], handler: @escaping (RemoteResult<[RemoteOrderUpdate]>) -> ()) {
        let params: [[String: AnyObject]] = orderUpdates.map{
            ["uuid": $0.uuid as AnyObject, "order": $0.order as AnyObject]
        }
        RemoteProvider.authenticatedRequestArray(.put, Urls.inventoriesOrder, params) {result in
            handler(result)
        }
    }
    
    func removeInventory(_ inventory: DBInventory, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        removeInventory(inventory.uuid, handler: handler)
    }

    func removeInventory(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.inventory + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func acceptInvitation(_ invitation: RemoteInventoryInvitation, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let parameters = toRequestParams(invitation, accept: true)
        RemoteProvider.authenticatedRequest(.post, Urls.inventoryInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func rejectInvitation(_ invitation: RemoteInventoryInvitation, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let parameters = toRequestParams(invitation, accept: false)
        RemoteProvider.authenticatedRequest(.post, Urls.inventoryInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func findInvitedUsers(_ inventoryUuid: String, handler: @escaping (RemoteResult<[RemoteSharedUser]>) -> Void) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.inventoryInvitedUsers + "/\(inventoryUuid)") {result in
            handler(result)
        }
    }
    
    func syncInventoriesWithInventoryItems(_ inventoriesSync: InventoriesSync, handler: @escaping (RemoteResult<RemoteInventoriesWithInventoryItemsSyncResult>) -> ()) {
        
        let inventoriesSyncDicts: [[String: AnyObject]] = inventoriesSync.inventoriesSyncs.map {inventorySync in
            
            let inventory = inventorySync.inventory
            
            let sharedUsers: [[String: AnyObject]] = inventory.users.map{self.toRequestParams($0)}
            
            var dict: [String: AnyObject] = [
                "uuid": inventory.uuid as AnyObject,
                "name": inventory.name as AnyObject,
                "users": sharedUsers as AnyObject,
            ]
            
            dict["lastUpdate"] = NSNumber(value: Int64(inventory.lastServerUpdate) as Int64)
            
            let inventoryItemsDicts = inventorySync.inventoryItemsSync.inventoryItems.map {toRequestParamsForSync($0)}
            let toRemoveDicts = inventorySync.inventoryItemsSync.toRemove.map{self.toRequestParamsToRemove($0)}
            let inventoryItemsSyncDict: [String: AnyObject] = [
                "inventoryItems": inventoryItemsDicts as AnyObject,
                "toRemove": toRemoveDicts as AnyObject
            ]
            
            dict["inventoryItems"] = inventoryItemsSyncDict as AnyObject?
            
            return dict
        }
        
        let toRemoveDicts = inventoriesSync.toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "inventories": inventoriesSyncDicts as AnyObject,
            "toRemove": toRemoveDicts as AnyObject
        ]
        
        _ = AlamofireHelper.authenticatedRequest(.post, Urls.inventoriesWithItemsSync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteInventoriesWithInventoryItemsSyncResult>) in
            handler(result)
        }
    }
    

    // TODO maybe generally use this for inventoryItem request params?
    func toRequestParamsForSync(_ inventoryItem: InventoryItem) -> [String: AnyObject] {
        return [:]
        // Commented because structural changes
//        var dict: [String: AnyObject] = [
//        
////            "quantityDelta": inventoryItem.quantityDelta as AnyObject,
//            "product": [
//                "uuid": inventoryItem.product.uuid as AnyObject,
//                "name": inventoryItem.product.name as AnyObject
//            ] as AnyObject,
//            "inventoryUuid": inventoryItem.inventory.uuid as AnyObject
//        ]
//        
//        dict["lastUpdate"] = NSNumber(value: Int64(inventoryItem.lastServerUpdate) as Int64)
//        
//        return dict
    }
    
    func toRequestParamsToRemove(_ inventoryItem: InventoryItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["inventoryUuid": inventoryItem.inventory.uuid as AnyObject, "productUuid": inventoryItem.product.uuid as AnyObject]
        dict["lastUpdate"] = NSNumber(value: Int64(inventoryItem.lastServerUpdate) as Int64)
        return dict
    }
    
    func toRequestParamsToRemove(_ inventory: DBInventory) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": inventory.uuid as AnyObject]
        dict["lastUpdate"] = NSNumber(value: Int64(inventory.lastServerUpdate) as Int64)
        return dict
    }
    
    func toRequestParams(_ sharedUserInput: DBSharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUserInput.email as AnyObject,
            "foo": "" as AnyObject // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }

    
    func toRequestParams(_ inventoryInput: DBInventory) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = inventoryInput.users.map{self.toRequestParams($0)}
        
        var inventoryDict: [String: AnyObject] = [
            "uuid": inventoryInput.uuid as AnyObject,
            "name": inventoryInput.name as AnyObject,
            "order": inventoryInput.order as AnyObject,
            "color": inventoryInput.bgColor().hexStr as AnyObject
        ]

        inventoryDict["lastUpdate"] = NSNumber(value: Int64(inventoryInput.lastServerUpdate) as Int64)
        
        inventoryDict["users"] = sharedUsers as AnyObject?
        
        return inventoryDict
    }
    
    func toRequestParams(_ invitation: RemoteInventoryInvitation, accept: Bool) -> [String: AnyObject] {
        
        let sharedUser = DBSharedUser(email: invitation.sender) // TODO as commented in the invitation objs, these should contain shared user not only email (this means the server has to send us the shared user)
        
        return [
            "uuid": invitation.inventory.uuid as AnyObject,
            "accept": accept as AnyObject,
            "sender": toRequestParams(sharedUser) as AnyObject
        ]
    }
}
