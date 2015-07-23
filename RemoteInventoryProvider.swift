//
//  RemoteInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteInventoryProvider {
    
    func inventories(handler: RemoteResult<[RemoteInventory]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.inventory).responseMyArray { (request, _, result: RemoteResult<[RemoteInventory]>, error) in
            handler(result)
        }
    }
    
    func addInventory(inventory: InventoryInput, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        AlamofireHelper.authenticatedRequest(.POST, Urls.inventory, params).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func updateInventory(inventory: InventoryInput, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = self.toRequestParams(inventory)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.inventory, params).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }

    func toRequestParams(sharedUserInput: SharedUserInput) -> [String: AnyObject] {
        return [
            "email": sharedUserInput.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }

    func toRequestParams(inventoryInput: InventoryInput) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = inventoryInput.users.map{self.toRequestParams($0)}
        
        var inventoryDict: [String: AnyObject] = [
            "uuid": inventoryInput.uuid,
            "name": inventoryInput.name
        ]

        inventoryDict["users"] = sharedUsers
        
        return inventoryDict
    }
}
