//
//  RemoteHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 15/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteHistoryItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    let inventoryUuid: String
    let productUuid: String
    let quantity: Int
    let userUuid: String
    let addedDate: NSDate
    
    @objc required init?(representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.inventoryUuid = representation.valueForKeyPath("inventoryUuid") as! String
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.userUuid = representation.valueForKeyPath("userUuid") as! String
        self.addedDate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("addedDate") as! Double)
    }
    
    static func collection(representation: AnyObject) -> [RemoteHistoryItem] {
        var listItems = [RemoteHistoryItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteHistoryItem(representation: obj) {
                listItems.append(listItem)
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), inventoryUuid: \(self.inventoryUuid), productUuid: \(self.productUuid), quantity: \(self.quantity), userUuid: \(self.userUuid), addedDate: \(self.addedDate)}"
    }
}
