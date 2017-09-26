//
//  RemoteInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteInventoryItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let quantity: Float
    public let productUuid: String // TODO remove this? or store product and inventory here not in RemoteInventoryItemWithProduct --- is this todo still valid?
    public let inventoryUuid: String
    public let lastUpdate: Int64
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let quantity = representation.value(forKeyPath: "quantity") as? Float,
            let productUuid = representation.value(forKeyPath: "productUuid") as? String,
            let inventoryUuid = representation.value(forKeyPath: "inventoryUuid") as? String,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                logger.e("Invalid json: \(representation)")
                return nil}

        self.uuid = uuid
        self.quantity = quantity
        self.productUuid = productUuid
        self.inventoryUuid = inventoryUuid
        self.lastUpdate = Int64(lastUpdate)
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteInventoryItem]? {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), quantity: \(quantity), productUuid: \(productUuid), invnetoryUuid: \(inventoryUuid), listUpdate: \(lastUpdate)}"
    }
}

public extension RemoteInventoryItem {
    public var timestampUpdateDict: [String: AnyObject] {
        return RemoteInventoryItem.createTimestampUpdateDict(uuid: uuid, lastUpdate: lastUpdate)
    }
    
    public static func createTimestampUpdateDict(uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
