//
//  RemoteInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let quantity: Int
    let productUuid: String // TODO remove this? or store product and inventory here not in RemoteInventoryItemWithProduct --- is this todo still valid?
    let inventoryUuid: String
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let quantity = representation.value(forKeyPath: "quantity") as? Int,
            let productUuid = representation.value(forKeyPath: "productUuid") as? String,
            let inventoryUuid = representation.value(forKeyPath: "inventoryUuid") as? String,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.uuid = uuid
        self.quantity = quantity
        self.productUuid = productUuid
        self.inventoryUuid = inventoryUuid
        self.lastUpdate = Int64(lastUpdate)
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteInventoryItem]? {
        var items = [RemoteInventoryItem]()
        for obj in representation {
            if let item = RemoteInventoryItem(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), quantity: \(quantity), productUuid: \(productUuid), invnetoryUuid: \(inventoryUuid), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteInventoryItem {
    var timestampUpdateDict: [String: AnyObject] {
        return RemoteInventoryItem.createTimestampUpdateDict(uuid: uuid, lastUpdate: lastUpdate)
    }
    
    static func createTimestampUpdateDict(uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
