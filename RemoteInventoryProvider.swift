//
//  RemoteInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import Valet

class RemoteInventoryProvider {
   
    func inventoryItems(handler: RemoteResult<[RemoteInventoryItemWithProduct]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.inventory).responseMyArray { (request, _, result: RemoteResult<[RemoteInventoryItemWithProduct]>, error) in
            handler(result)
        }
    }
    
    func addToInventory(inventoryItems: [InventoryItem], handler: RemoteResult<NoOpSerializable> -> ()) {

        func toDictionary(inventoryItem: InventoryItem) -> [String: AnyObject] {
            return [
                "product": [
                    "uuid": inventoryItem.product.uuid,
                    "name": inventoryItem.product.name,
                    "price": inventoryItem.product.price
                ],
                "inventoryItem": [
                    "uuid": inventoryItem.uuid,
                    "quantity": inventoryItem.quantity,
                    "inventoryUuid": "???", // this is for now not used - only 1 inventory per user
                    "productUuid": inventoryItem.product.uuid
                ]
            ]
        }
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.inventory)!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        let values = inventoryItems.map{toDictionary($0)}
        
        var error: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(values, options: nil, error: &error)
        
        Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
}
