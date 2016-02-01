//
//  RemoteGroupItem.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteGroupItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    let quantity: Int
    let productUuid: String
    let groupUuid: String
    let lastUpdate: NSDate
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.groupUuid = representation.valueForKeyPath("groupUuid") as! String
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteGroupItem] {
        var listItems = [RemoteGroupItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteGroupItem(response: response, representation: obj) {
                listItems.append(listItem)
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
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}