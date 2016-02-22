//
//  RemotePlanItem.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct RemotePlanItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let inventoryUuid: String
    let productUuid: String
    let quantity: Int
    
    init?(representation: AnyObject) {
        guard
            let inventoryUuid = representation.valueForKeyPath("inventoryUuid") as? String,
            let productUuid = representation.valueForKeyPath("productUuid") as? String,
            let quantity = representation.valueForKeyPath("quantity") as? Int
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.inventoryUuid = inventoryUuid
        self.productUuid = productUuid
        self.quantity = quantity
    }
    
    static func collection(representation: AnyObject) -> [RemotePlanItem]? {
        var listItems = [RemotePlanItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemotePlanItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryUuid: \(inventoryUuid), productUuid: \(productUuid), quantity: \(quantity)}"
    }
}