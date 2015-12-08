//
//  RemotePlanItem.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemotePlanItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let inventoryUuid: String
    let productUuid: String
    let quantity: Int
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.inventoryUuid = representation.valueForKeyPath("inventoryUuid") as! String
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.quantity = representation.valueForKeyPath("quantity") as! Int
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemotePlanItem] {
        var listItems = [RemotePlanItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemotePlanItem(response: response, representation: obj) {
                listItems.append(listItem)
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryUuid: \(inventoryUuid), productUuid: \(productUuid), quantity: \(quantity)}"
    }
}