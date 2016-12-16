//
//  InventoryItemId.swift
//  shoppin
//
//  Created by ischuetz on 11/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public final class InventoryItemId {
 
    public let inventoryUuid: String
    public let productUuid: String
    
    public init(inventoryUuid: String, productUuid: String) {
        self.inventoryUuid = inventoryUuid
        self.productUuid = productUuid
    }
}
