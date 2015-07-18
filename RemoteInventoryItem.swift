//
//  RemoteInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteInventoryItem: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    let quantity: Int
    let productUuid: String
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryItem] {
        var items = [RemoteInventoryItem]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteInventoryItem(response: response, representation: obj) {
                items.append(item)
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) quantity: \(self.quantity), productUuid: \(self.productUuid)}"
    }
}