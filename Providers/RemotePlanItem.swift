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
    let quantity: Float
    
    init?(representation: AnyObject) {
        guard
            let inventoryUuid = representation.value(forKeyPath: "inventoryUuid") as? String,
            let productUuid = representation.value(forKeyPath: "productUuid") as? String,
            let quantity = representation.value(forKeyPath: "quantity") as? Float
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.inventoryUuid = inventoryUuid
        self.productUuid = productUuid
        self.quantity = quantity
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemotePlanItem]? {
        var listItems = [RemotePlanItem]()
        for obj in representation {
            if let listItem = RemotePlanItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventoryUuid: \(inventoryUuid), productUuid: \(productUuid), quantity: \(quantity)}"
    }
}
