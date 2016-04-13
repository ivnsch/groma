//
//  RemoteGroupItem.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteGroupItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    let quantity: Int
    let productUuid: String
    let groupUuid: String
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let quantity = representation.valueForKeyPath("quantity") as? Int,
            let productUuid = representation.valueForKeyPath("productUuid") as? String,
            let groupUuid = representation.valueForKeyPath("groupUuid") as? String,
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.quantity = quantity
        self.productUuid = productUuid
        self.groupUuid = groupUuid
        self.lastUpdate = Int64(lastUpdate)
    }
    
    static func collection(representation: AnyObject) -> [RemoteGroupItem]? {
        var listItems = [RemoteGroupItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteGroupItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), productUuid: \(productUuid), groupUuid: \(groupUuid), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteGroupItem {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    static func createTimestampUpdateDict(uuid uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
