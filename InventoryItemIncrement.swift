//
//  InventoryItemIncrement.swift
//  shoppin
//
//  Created by ischuetz on 10/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItemIncrement: CustomDebugStringConvertible {
    
    let delta: Int
    let productUuid: String
    let inventoryUuid: String
    
    init(delta: Int, productUuid: String, inventoryUuid: String) {
        self.delta = delta
        self.productUuid = productUuid
        self.inventoryUuid = inventoryUuid
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) delta: \(delta), productUuid: \(productUuid)}, inventoryUuid: \(inventoryUuid)}"
    }
}