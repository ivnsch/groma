//
//  RemoteHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RemoteHistoryItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    let inventoryUuid: String
    let productUuid: String
    let quantity: Int
    let userUuid: String
    let addedDate: Int64
    let lastUpdate: Int64
    let paidPrice: Float
    
    init?(representation: AnyObject) {
        
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let inventoryUuid = representation.valueForKeyPath("inventoryUuid") as? String,
            let productUuid = representation.valueForKeyPath("productUuid") as? String,
            let quantity = representation.valueForKeyPath("quantity") as? Int,
            let userUuid = representation.valueForKeyPath("userUuid") as? String,
            let addedDate = representation.valueForKeyPath("addedDate") as? Double,
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double,
            let paidPrice = representation.valueForKeyPath("paidPrice") as? Float
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.inventoryUuid = inventoryUuid
        self.productUuid = productUuid
        self.quantity = quantity
        self.userUuid = userUuid
        self.addedDate = Int64(addedDate)
        self.lastUpdate = Int64(lastUpdate)
        self.paidPrice = paidPrice
    }
    
    static func collection(representation: AnyObject) -> [RemoteHistoryItem]? {
        var listItems = [RemoteHistoryItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteHistoryItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), inventoryUuid: \(inventoryUuid), productUuid: \(productUuid), quantity: \(quantity), userUuid: \(userUuid), addedDate: \(addedDate), lastUpdate: \(lastUpdate), paidPrice: \(paidPrice)}"
    }
}

extension RemoteHistoryItem {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}