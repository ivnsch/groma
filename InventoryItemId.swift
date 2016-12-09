//
//  InventoryItemId.swift
//  shoppin
//
//  Created by ischuetz on 11/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class InventoryItemId {
 
    let inventoryUuid: String
    let productUuid: String
    
    init(inventoryUuid: String, productUuid: String) {
        self.inventoryUuid = inventoryUuid
        self.productUuid = productUuid
    }
}
