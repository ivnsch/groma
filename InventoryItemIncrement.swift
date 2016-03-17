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
    let inventoryItemUuid: String
    
    init(delta: Int, inventoryItemUuid: String) {
        self.delta = delta
        self.inventoryItemUuid = inventoryItemUuid
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) delta: \(delta), inventoryUuid: \(inventoryItemUuid)}"
    }
}