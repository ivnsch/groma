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
    let productUuid: String // TODO remove this? or store product and inventory here not in RemoteInventoryItemWithProduct
    
    init?(representation: AnyObject) {
        guard
            let quantity = representation.valueForKeyPath("quantity") as? Int,
            let productUuid = representation.valueForKeyPath("productUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.quantity = quantity
        self.productUuid = productUuid
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
        return "{\(self.dynamicType) quantity: \(quantity), productUuid: \(productUuid)}"
    }
}