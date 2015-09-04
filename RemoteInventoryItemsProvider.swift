//
//  RemoteInventoryItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet
import Alamofire

class RemoteInventoryItemsProvider: Any {
    
    func inventoryItems(inventory: Inventory, handler: RemoteResult<[RemoteInventoryItemWithProduct]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.inventoryItems, ["inventory": inventory.uuid]).responseMyArray { (request, _, result: RemoteResult<[RemoteInventoryItemWithProduct]>) in
            handler(result)
        }
    }
    
    func addToInventory(inventory: Inventory, inventoryItems: [InventoryItemWithHistoryEntry], handler: RemoteResult<NoOpSerializable> -> ()) {
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.inventoryItems + "/\(inventory.uuid)")!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        let values = inventoryItems.map{[weak self] in self!.toDictionary($0)}
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(values, options: [])
            
            Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>) in
                handler(result)
            }
            
        } catch _ as NSError {
            handler(RemoteResult(status: .ClientParamsParsingError))
        }
    }
    
    func incrementInventoryItem(inventoryItem: InventoryItem, delta: Int, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params: [String: AnyObject] = [
            "delta": delta,
            "productUuid": inventoryItem.product.uuid,
            "inventoryUuid": inventoryItem.inventory.uuid
        ]
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.incrementInventoryItem, params).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    // TODO remote inventory from inventory items, at least for sending - we want to add all the items to one inventory....... for receiving this also wastes payload, they also have the same inventory also
    private func toDictionary(inventoryItem: InventoryItemWithHistoryEntry) -> [String: AnyObject] {
        return [
            "product": [
                "uuid": inventoryItem.inventoryItem.product.uuid,
                "name": inventoryItem.inventoryItem.product.name,
                "price": inventoryItem.inventoryItem.product.price
            ],
            "inventoryItem": [
                "quantity": inventoryItem.inventoryItem.quantityDelta,
                "inventoryUuid": inventoryItem.inventoryItem.inventory.uuid,
                "productUuid": inventoryItem.inventoryItem.product.uuid
            ],
            "historyItemUuid": inventoryItem.historyItemUuid,
            "addedDate": NSNumber(double: inventoryItem.addedDate.timeIntervalSince1970).longValue,
            "user": self.toRequestParams(inventoryItem.user)
        ]
    }
    
    private func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
}
