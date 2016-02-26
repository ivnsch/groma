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
    let quantity: Int
    let productUuid: String // TODO remove this? or store product and inventory here not in RemoteInventoryItemWithProduct --- is this todo still valid?
    let inventoryUuid: String
    let lastUpdate: NSDate
    
    init?(representation: AnyObject) {
        guard
            let quantity = representation.valueForKeyPath("quantity") as? Int,
            let productUuid = representation.valueForKeyPath("productUuid") as? String,
            let inventoryUuid = representation.valueForKeyPath("inventoryUuid") as? String,
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.quantity = quantity
        self.productUuid = productUuid
        self.inventoryUuid = inventoryUuid
        self.lastUpdate = lastUpdate
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryItem]? {
        var items = [RemoteInventoryItem]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteInventoryItem(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) quantity: \(quantity), productUuid: \(productUuid), invnetoryUuid: \(inventoryUuid), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteInventoryItem {
    var timestampUpdateDict: [String: AnyObject] {
        return ["productUuid": productUuid, "inventoryUuid": inventoryUuid, "lastupdate": lastUpdate, "dirty": false]
    }
}