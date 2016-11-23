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
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let inventoryUuid = representation.value(forKeyPath: "inventoryUuid") as? String,
            let productUuid = representation.value(forKeyPath: "productUuid") as? String,
            let quantity = representation.value(forKeyPath: "quantity") as? Int,
            let userUuid = representation.value(forKeyPath: "userUuid") as? String,
            let addedDate = representation.value(forKeyPath: "addedDate") as? Double,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double,
            let paidPrice = representation.value(forKeyPath: "paidPrice") as? Float
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
    
    static func collection(_ representation: [AnyObject]) -> [RemoteHistoryItem]? {
        var listItems = [RemoteHistoryItem]()
        for obj in representation {
            if let listItem = RemoteHistoryItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), inventoryUuid: \(inventoryUuid), productUuid: \(productUuid), quantity: \(quantity), userUuid: \(userUuid), addedDate: \(addedDate), lastUpdate: \(lastUpdate), paidPrice: \(paidPrice)}"
    }
}

extension RemoteHistoryItem {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
