//
//  RemoteInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteInventoryProvider: RemoteProvider {
    
    func inventories(handler: RemoteResult<[RemoteInventory]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.inventory).responseMyArray { (request, _, result: RemoteResult<[RemoteInventory]>, error) in
            handler(result)
        }
    }
    
    func syncInventories(inventories: [Inventory], toRemove: [Inventory], handler: RemoteResult<RemoteSyncResult<RemoteInventory>> -> ()) {
        
        let inventoriesParams = inventories.map{self.toRequestParams($0)}
        let toRemoveParams = toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "inventories": inventoriesParams,
            "toRemove": toRemoveParams
        ]
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.inventorySync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteSyncResult<RemoteInventory>>, error) in
            handler(result)
        }
    }
    
    func addInventory(inventory: Inventory, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        AlamofireHelper.authenticatedRequest(.POST, Urls.inventory, params).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func updateInventory(inventory: Inventory, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.inventory, params).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
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
            "name": inventoryInput.name
        ]

        if let lastServerUpdate = inventoryInput.lastServerUpdate {
            inventoryDict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        
        inventoryDict["users"] = sharedUsers
        
        return inventoryDict
    }
}
