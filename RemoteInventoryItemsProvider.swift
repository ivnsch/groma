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
        AlamofireHelper.authenticatedRequest(.GET, Urls.inventoryItems).responseMyArray { (request, _, result: RemoteResult<[RemoteInventoryItemWithProduct]>, error) in
            handler(result)
        }
    }
    
    func addToInventory(inventory: Inventory, inventoryItems: [InventoryItem], handler: RemoteResult<NoOpSerializable> -> ()) {
        
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.inventoryItems)!)
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
            
            Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>, error) in
                handler(result)
            }
            
        } catch _ as NSError {
            handler(RemoteResult(status: .ClientParamsParsingError))
        }
    }
    
    private func toDictionary(inventoryItem: InventoryItem) -> [String: AnyObject] {
        return [
            "product": [
                "uuid": inventoryItem.product.uuid,
                "name": inventoryItem.product.name,
                "price": inventoryItem.product.price
            ],
            "inventoryItem": [
                "quantity": inventoryItem.quantity,
                "inventoryUuid": inventoryItem.inventory.uuid,
                "productUuid": inventoryItem.product.uuid
            ],
            "inventory": [
                "uuid": inventoryItem.inventory.uuid,
                "name": inventoryItem.inventory.name
            ]
        ]
    }
}
